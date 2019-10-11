class DodonaLineAnnotatedFormatter < DodonaCodeTableFormatter
  require 'builder'

  def initialize(formatter, annotations, opts = {})
    super(formatter, opts)
    @sorted_annotations = annotations.sort_by { |annotation| annotation[:row] }
  end

  def extra_line_callback(lineno)
    return nil if @sorted_annotations.empty?

    until @sorted_annotations.empty?
      first_annotation = @sorted_annotations.first
      return unless first_annotation[:row] + 1 == lineno

      # Create the actual annotation line
      @builder.tr(class: @line_class) do
        @builder.td(class: @gutter_class) do
          send("icon_#{first_annotation[:type]}")
        end
        @builder.td(class: 'annotation', colspan: 2, style: '-moz-user-select: none;-ms-user-select: none; -webkit-user-select: none;user-select: none;') do
          @builder.text! first_annotation[:text].split("\n")[0]
        end
      end

      # Remove the annotation from the FIFO queue
      @sorted_annotations.shift
    end
  end

  def icon_testcase
    @builder.span('► ', class: 'testcase-icon')
  end

  def icon_correct
    @builder.i('', class: 'mdi mdi-check mdi-18')
  end

  def icon_wrong
    @builder.i('', class: 'mdi-close mdi mdi-18')
  end

  def icon_warning
    @builder.i('', class: 'mdi mdi-alert mdi-18')
  end

  def icon_error
    @builder.i('', class: 'mdi mdi-alert-circle mdi-18')
  end

  def icon_info
    @builder.i('', class: 'mdi mdi-alert-circle mdi-18')
  end
end
