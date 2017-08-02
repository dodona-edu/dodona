require 'json'         # JSON support
require 'json-schema'  # json schema validation, from json-schema gem

class ResultConstructorError < StandardError
  attr_accessor :title, :description
  def initialize(title, description=nil)
    @title = title
    @description = description
  end
end

class ResultConstructor
  FULL_SCHEMA = JSON.parse(File.read(Rails.root.join('public/schemas/judge_output.json')))
  PART_SCHEMA = JSON.parse(File.read(Rails.root.join('public/schemas/partial_output.json')))

  LEVELSA = [:judgement, :tab, :context, :testcase, :test]
  LEVELSH = { judgement: 0, tab: 1, context: 2, testcase: 3, test: 4 }
  GATHER = { tab: :groups, context: :groups, testcase: :groups, test: :tests }

  def initialize
    @level = nil
    @result = Hash.new
  end

  def feed(judge_output)
    split_jsons(judge_output).each do |json|
      if JSON::Validator.validate(PART_SCHEMA, json)
        update(json)
      elsif JSON::Validator.validate(FULL_SCHEMA, json)
        @result = json
      else
        raise ResultConstructorError.new(
          "Judge output is not a valid json",
          json.to_s
        )
      end
    end
  end

  def result
    if @level.nil?
      @result
    else
      # unclosed judgement. timeout?
    end
  end

  # below are the methods open to partial updates

  def start_judgement
    check_level(nil, "judgement started")
    @level = :judgement
    @judgement = Hash.new
    @judgement[:accepted] = true
    @judgement[:status] = "correct"
  end

  def start_tab(title: nil)
    check_level(:judgement, "tab started")
    @tab = Hash.new
    @tab[:description] = title
    @level = :tab
  end

  def start_context(description: nil)
    check_level(:tab, "context started")
    @context = Hash.new
    @context[:description] = description if description.present?
    @context[:accepted] = true
    @level = :context
  end

  def start_testcase(description: nil)
    check_level(:context, "testcase started")
    @testcase = Hash.new
    @testcase[:description] = description
    @testcase[:accepted] = true
    @level = :testcase
  end

  def start_test(description: nil, expected: nil)
    check_level(:testcase, "test started")
    @test = Hash.new
    @test[:description] = description if description.present?
    @test[:expected] = expected
    @level = :test
  end

  def append_message(message: nil)
    messages = current_item[:messages] ||= []
    messages << message if message.present?
  end

  def close_test(generated: nil, accepted: nil, status: nil)
    check_level(:test, "test closed")
    @test[:generated] = generated
    status = Submission::normalize_status(status)
    @test[:accepted] = if accepted.nil?
                       then status == 'correct'
                       else accepted
                       end
    @judgement[:status] = worsen(@judgement[:status], status)
    @testcase[:accepted] &&= @test[:accepted]
    (@testcase[:tests] ||= []) << @test
    @test = nil
    @level = :testcase
  end

  def close_testcase(accepted: nil)
    check_level(:testcase, "testcase closed")
    @testcase[:accepted] = accepted if accepted.present?
    @context[:accepted] &&= @testcase[:accepted]
    (@context[:groups] ||= []) << @testcase
    @testcase = nil
    @level = :context
  end

  def close_context(accepted: nil)
    check_level(:context, "context closed")
    @context[:accepted] = accepted if accepted.present?
    @judgement[:accepted] &&= @context[:accepted]
    (@tab[:groups] ||= []) << @context
    @context = nil
    @level = :tab
  end

  def close_tab(badgeCount: nil)
    check_level(:tab, "tab closed")
    @tab[:badgeCount] = badgeCount if badgeCount.present?
    (@judgement[:groups] ||= []) << @tab
    @tab = nil
    @level = :judgement
  end

  def close_judgement(accepted: nil, status: nil)
    if @level != :judgement
      raise ResultConstructorError.new "Judgement closed during level #{@level.to_s}"
    end
    @judgement[:accepted] = accepted if accepted.present?
    @judgement[:status] = status if status.present?
    @result = @judgement
    @judgement = nil
    @level = nil
  end

  private

  def split_jsons(string)
    parse_exception = nil
    jsons = [""]
    string.split(/(?<=})\s*(?={)/).each do |new|
      jsons.last << new
      begin
        jsons[-1] = JSON.parse(jsons.last, symbolize_names: true)
        parse_exception = nil
        jsons << ""
      rescue JSON::ParserError => e
        parse_exception = e
      end
    end
    if parse_exception.present?
      raise ResultConstructorError.new("Failed to parse the following JSON", string)
    else
      jsons[0...-1]
    end
  end

  # apply a partial update
  def update(json)
    command = json.delete(:command).gsub('-', '_')
    if json.empty?
      send command
    else
      send command, json
    end
  end

  def check_level(should, situation)
    if should != @level
      raise ResultConstructorError.new "#{situation} during #{situation}"
    end
  end

  EVILNESS = [
    "internal error",
    "compilation error",
    "runtime error",
    "wrong",
    "correct"
  ].each_with_index.reduce(Hash.new) do |memo,pair|
    memo.merge(pair[0] => pair[1])
  end

  def worsen(current, new)
    [current, new].min_by { |e| EVILNESS[e] }
  end

  def current_item
    instance_variable_get("@#{@level}")
  end

end
