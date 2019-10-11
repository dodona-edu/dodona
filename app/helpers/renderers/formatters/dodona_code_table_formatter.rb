class DodonaCodeTableFormatter < Rouge::Formatter
  require 'builder'

  def initialize(formatter, opts = {})
    @formatter = formatter
    @start_line = opts.fetch :start_line, 1
    @table_class = opts.fetch :table_class, 'rouge-line-table'
    @gutter_class = opts.fetch :gutter_class, 'rouge-gutter'
    @code_class = opts.fetch :code_class, 'rouge-code'
    @line_class = opts.fetch :line_class, 'lineno'
    @line_id = opts.fetch :line_id, 'line-%i'
    @builder = Builder::XmlMarkup.new
  end

  def stream(tokens, &_)
    lineno = @start_line - 1

    @builder.table(class: @table_class) do
      @builder.tbody do
        token_lines(tokens) do |line_tokens|
          lineno += 1
          @builder.tr(id: @line_id % lineno, class: "#{@line_class} #{line_class_callback lineno}") do
            @builder.td(class: "#{@gutter_class} gl", style: '-moz-user-select: none;-ms-user-select: none; -webkit-user-select: none;user-select: none;') do
              before_gutter_callback(lineno)
              @builder << lineno.to_s
              after_gutter_callback(lineno)
            end
            @builder.td(class: @code_class) do
              before_code_callback(lineno)
              @formatter.stream(line_tokens) { |formatted| @builder << formatted }
              after_code_callback(lineno)
            end
          end
          extra_line_callback(lineno)
        end
      end
    end
    yield @builder
  end

  def before_gutter_callback(_)
    nil
  end

  def after_gutter_callback(_)
    nil
  end

  def after_code_callback(_)
    nil
  end

  def before_code_callback(_)
    nil
  end

  def line_class_callback(_)
    nil
  end

  def extra_line_callback(_)
    nil
  end
end
