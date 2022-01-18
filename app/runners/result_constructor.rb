require 'json' # JSON support
require 'json-schema' # json schema validation, from json-schema gem

class ResultConstructorError < StandardError
  attr_accessor :title, :description

  def initialize(title, description = nil)
    super()
    @title = title
    @description = description
  end
end

class ResultConstructor
  FULL_SCHEMA = JSON.parse(File.read(Rails.root.join('public/schemas/judge_output.json')))
  PART_SCHEMA = JSON.parse(File.read(Rails.root.join('public/schemas/partial_output.json')))

  LEVELSA = %i[judgement tab context testcase test].freeze
  LEVELSH = { judgement: 0, tab: 1, context: 2, testcase: 3, test: 4 }.freeze
  GATHER = { tab: :groups, context: :groups, testcase: :groups, test: :tests }.freeze

  def initialize(locale)
    @locale = locale
    @level = nil
    @result = {}
  end

  def feed(judge_output)
    raise ResultConstructorError, 'No judge output' if judge_output.empty?

    split_jsons(judge_output).each do |json|
      if JSON::Validator.validate(PART_SCHEMA, json)
        update(json)
      elsif JSON::Validator.validate(FULL_SCHEMA, json)
        @result = json
      else
        raise ResultConstructorError.new(
          'Judge output is not a valid json',
          json.to_s
        )
      end
    end
  end

  def result(timeout)
    # prepare status for possible timeout
    reason = timeout ? 'time limit exceeded' : 'memory limit exceeded'
    status = { enum: reason,
               human: I18n.t("activerecord.attributes.submission.statuses.#{reason}",
                             locale: @locale) }

    # close the levels left open
    close_test(generated: '', accepted: false, status: status) if @level == :test
    close_testcase(accepted: false) if @level == :testcase
    close_context(accepted: false) if @level == :context
    close_tab(badgeCount: @tab[:badgeCount] || 1) if @level == :tab
    close_judgement(accepted: false, status: status) if @level == :judgement

    @result
  end

  # below are the methods open to partial updates

  def start_judgement
    check_level(nil, 'judgement started')
    @level = :judgement
    @judgement = {}
    @judgement[:accepted] = true
    @judgement[:status] = 'correct'
    @judgement[:description] = I18n.t('activerecord.attributes.submission.statuses.correct',
                                      locale: @locale)
  end

  def start_tab(title: nil, hidden: nil, permission: nil)
    check_level(:judgement, 'tab started')
    @tab = {}
    @tab[:description] = title
    @tab[:badgeCount] = 0
    @tab[:permission] = permission unless permission.nil?
    @hiddentab = hidden || false
    @level = :tab
  end

  def start_context(description: nil)
    check_level(:tab, 'context started')
    @context = {}
    @context[:description] = description unless description.nil?
    @context[:accepted] = true
    @level = :context
  end

  def start_testcase(description: nil)
    check_level(:context, 'testcase started')
    @testcase = {}
    @testcase[:description] = description
    @testcase[:accepted] = true
    @level = :testcase
  end

  def start_test(description: nil, expected: nil, channel: nil, format: nil)
    check_level(:testcase, 'test started')
    @test = {}
    @test[:description] = description unless description.nil?
    @test[:expected] = expected
    @test[:channel] = channel unless channel.nil?
    @test[:format] = format unless format.nil?
    @level = :test
  end

  def append_message(message: nil)
    messages = current_item[:messages] ||= []
    messages << message unless message.nil?
  end

  def annotate_code(values)
    (@judgement[:annotations] ||= []) << {
      text: values[:text] || '',
      type: values[:type] || 'info',
      row: values[:row] || 0,
      rows: values[:rows] || 1,
      column: values[:column] || 0,
      columns: values[:columns] || 1,
      externalUrl: values[:externalUrl] || nil
    }
  end

  def escalate_status(status: nil)
    status[:enum] = Submission.normalize_status(status[:enum])
    return unless worse?(@judgement[:status], status[:enum])

    @judgement[:status] = status[:enum]
    @judgement[:description] = status[:human]
  end

  def close_test(generated: nil, accepted: nil, status: nil)
    check_level(:test, 'test closed')
    @test[:generated] = generated
    escalate_status(status: status)
    @test[:accepted] = if accepted.nil?
                       then status[:enum] == 'correct'
                       else
                         accepted
                       end
    @testcase[:accepted] &&= @test[:accepted]
    (@testcase[:tests] ||= []) << @test
    @test = nil
    @level = :testcase
  end

  def close_testcase(accepted: nil)
    check_level(:testcase, 'testcase closed')
    @testcase[:accepted] = accepted unless accepted.nil?
    @tab[:badgeCount] += 1 unless @testcase[:accepted]
    @context[:accepted] &&= @testcase[:accepted]
    (@context[:groups] ||= []) << @testcase
    @testcase = nil
    @level = :context
  end

  def close_context(accepted: nil)
    check_level(:context, 'context closed')
    @context[:accepted] = accepted unless accepted.nil?
    @judgement[:accepted] &&= @context[:accepted]
    @hiddentab &&= @context[:accepted]
    (@tab[:groups] ||= []) << @context
    @context = nil
    @level = :tab
  end

  # rubocop:disable Naming/VariableName
  # This variable has to be camelCase because it is taken straight from JSON
  def close_tab(badgeCount: nil)
    check_level(:tab, 'tab closed')
    @tab[:badgeCount] = badgeCount unless badgeCount.nil?
    (@judgement[:groups] ||= []) << @tab unless @hiddentab
    @tab = nil
    @level = :judgement
  end
  # rubocop:enable Naming/VariableName

  def close_judgement(accepted: nil, status: nil)
    check_level(:judgement, 'judgement closed')
    @judgement[:accepted] = accepted unless accepted.nil?
    @judgement[:status] = status[:enum] unless status.nil?
    @judgement[:description] = status[:human] unless status.nil?
    @result = @judgement
    @judgement = nil
    @level = nil
  end

  private

  def split_jsons(string)
    parse_exception = nil
    jsons = ['']
    string.split(/(?<=})\s*(?={)/).each do |new|
      jsons.last << new
      begin
        jsons[-1] = JSON.parse(jsons.last, symbolize_names: true)
        parse_exception = nil
        jsons << ''
      rescue JSON::ParserError => e
        parse_exception = e
      end
    end
    raise ResultConstructorError.new('Failed to parse the following JSON', string) if parse_exception.present?

    jsons[0...-1]
  end

  # apply a partial update
  def update(json)
    command = json.delete(:command).tr('-', '_')
    if json.empty?
      send command
    else
      send command, **json
    end
  end

  def check_level(should, situation)
    raise ResultConstructorError, "#{situation} during #{@level}" if should != @level
  end

  EVILNESS = [
    'correct',
    'wrong',
    'output limit exceeded',
    'runtime error',
    'compilation error',
    'memory limit exceeded',
    'time limit exceeded',
    'internal error'
  ].each_with_index.reduce({}) do |memo, pair|
    memo.merge(pair[0] => pair[1])
  end

  def worse?(current, new)
    EVILNESS[new] > EVILNESS[current]
  end

  def current_item
    instance_variable_get("@#{@level}")
  end
end
