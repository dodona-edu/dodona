require 'json'         # JSON support
require 'json-schema'  # json schema validation, from json-schema gem

class ResultConstructorError < StandardError
  attr_accessor :title, :description
  def initialize(title, description)
    @title = title
    @description = description
  end
end

class ResultConstructor
  FULL_SCHEMA = JSON.parse(File.read(Rails.root.join('public/schemas/judge_output.json')))
  PART_SCHEMA = JSON.parse(File.read(Rails.root.join('public/schemas/partial_output.json')))

  LEVELSA = [:tab, :context, :testcase, :test]
  LEVELSH = { tab: 0, context: 1, testcase: 2, test: 3 }
  GATHER = { tab: :groups, context: :groups, testcase: :groups, test: :tests }

  attr_reader :result

  def initialize
    @result = Hash.new
    @focus = []
    @stack = []
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
          judge_output
        )
      end
    end
  end

  # below are the methods open to partial updates

  def focus(focus={})
    if focus.empty?
      @focus = []
    else
      LEVELSA.each_with_index do |key, level|
        if focus.key?(key)
          @focus.slice!(level, @focus.length)
          @focus[level] = focus[key]
        end
      end
    end
  end

  def push_focus
    @stack << @focus.dup
  end

  def pop_focus
    @focus = @stack.pop
  end

  def focus_relative(level: nil)
    level = level.to_sym
    until @focus.empty? || level == LEVELSA[@focus.length - 1]
      @focus.pop
    end
  end

  def new_tab; new(:tab); end
  def new_context; new(:context); end
  def new_testcase; new(:testcase); end
  def new_test; new(:test); end

  def append_message(message: nil)
    messages = current_item[:messages] ||= []
    messages << message if message.present?
  end

  def set_properties(properties)
    current_item.update(properties)
  end

  def increment_badgecount
    current_item[:badgecount] += 1
  end

  private

  # returns the list and index for the given level
  def current(what)
    subresult = @result
    LEVELSA.each_with_index do |key, level|
      collection = subresult[GATHER[key]]          ||= []
      subresult  = collection[@focus[level] || 0]  ||= {}
      if key == what
        return [collection, @focus[level]]
      else
        @focus[level] ||= 0
      end
    end
  end

  # return the current focussed item
  def current_item
    subresult = @result
    @focus.each_with_index do |index, level|
      collection = subresult[GATHER[LEVELSA[level]]] ||= []
      subresult  = collection[index]                 ||= {}
    end
    subresult
  end

  # used by new tab, ...
  def new(what)
    tabs, index = current(what)
    @focus.slice!(LEVELSH[what], @focus.length)
    @focus[LEVELSH[what]] = if index.nil? then 0 else index + 1 end
  end

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

end
