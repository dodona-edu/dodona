class PythiaRenderer < FeedbackTableRenderer
  include ActionView::Helpers::JavaScriptHelper

  def parse
    tutor_init
    super
  end

  def show_code_tab
    return true unless @result[:groups]

    @result[:groups].none? { |t| t[:data][:source_annotations] }
  end

  def tab_content(t)
    if t[:data][:source_annotations]
      linting(t[:data][:source_annotations], @code)
    else
      super
    end
  end

  def diff(t)
    if t[:data][:diff]
      pythia_diff(t[:data][:diff])
    else
      super
    end
  end

  def test_accepted(t)
    if t[:data][:diff]
      @builder.div(class: 'test-accepted') do
        @builder.span(class: 'output') do
          html = t[:data][:diff].map do |l|
            if !l[2].nil?
              strip_outer_html(l[2])
            elsif !l[3].nil?
              strip_outer_html(l[3])
            else
              '' # This shouldn't happen, but it's the Python judge, so you never know
            end
          end.reduce { |l1, l2| "#{l1}\n#{l2}" }
          @builder << safe(html)
        end
      end
    else
      super
    end
  end

  def output_message(m)
    if m[:format].in?(%w[traceback])
      @builder.div(class: 'code wrong') do
        @builder.text! m[:description]
      end
    else
      super(m)
    end
  end

  def group(g)
    if g.key?(:data)
      @builder.div(class: "row group #{g[:accepted] ? 'correct' : 'wrong'}",
                   "data-statements": (g[:data][:statements]).to_s,
                   "data-stdin": (g[:data][:stdin]).to_s) do
        @builder.div(class: 'tutor-strip tutorlink', title: 'Start debugger') do
          @builder.div(class: 'tutor-strip-icon') do
            @builder.i('', class: 'mdi mdi-launch mdi-18')
          end
        end
        if g[:description]
          @builder.div(class: 'col-xs-12 description') do
            message(g[:description])
          end
        end
        messages(g[:messages])
        g[:groups]&.each { |tc| testcase(tc) }
      end
    else
      super(g)
    end
  end

  def testcase(tc)
    return super(tc) unless tc[:data] && tc[:data][:files]

    jsonfiles = tc[:data][:files].to_a.map do |key, value|
      value[:content] = "#{value[:content]}?token=#{@exercise.access_token}" \
        if @exercise.access_private? && value&.dig(:location) == 'href'
      [key, value]
    end.to_h.to_json
    @builder.div(class: "testcase #{tc[:accepted] ? 'correct' : 'wrong'} contains-file", "data-files": jsonfiles) do
      testcase_content(tc)
    end
  end

  ## custom methods

  def tutor_init
    # Initialize tutor javascript
    @builder.script do
      escaped = escape_javascript(@code.strip)
      @builder << '$(function() {'
      @builder << "$('#tutor').appendTo('body');"
      @builder << "var code = \"#{escaped}\";"
      @builder << "dodona.initPythiaSubmissionShow(code, '#{activity_path(nil, @exercise)}');});"
    end

    # Tutor HTML
    @builder.div(id: 'tutor', class: 'tutormodal') do
      @builder.div(id: 'info-modal', class: 'modal fade modal-info', "data-backdrop": true, tabindex: -1) do
        @builder.div(class: 'modal-dialog tutor') do
          @builder.div(class: 'modal-content') do
            @builder.div(class: 'modal-header') do
              @builder.div(class: 'icons') do
                @builder.button(id: 'fullscreen-button', type: 'button', class: 'btn btn-link btn-xs') do
                  @builder.i('', class: 'mdi mdi-fullscreen mdi-18')
                end
                @builder.button(type: 'button', class: 'btn btn-link btn-xs', "data-dismiss": 'modal') do
                  @builder.i('', class: 'mdi mdi-close mdi-18')
                end
              end
              @builder.h4(class: 'modal-title')
            end
            @builder.div(class: 'modal-body') {}
          end
        end
      end
    end
  end

  def strip_outer_html(diff_line_item)
    # Some pythia diff output includes newlines, which should never
    # happen, since each diff item represents a line. The newlines
    # mess up the regexes below.
    diff_line_item
      .delete("\n")
      .gsub(%r{<li[^>]*>(.*)</li>}, '\\1')
      .gsub(%r{<ins>(.*)</ins>}, '\\1')
      .gsub(%r{<del>(.*)</del>}, '\\1')
      .gsub(%r{<span>(.*)</span>}, '\\1')
  end

  def pythia_diff(diff)
    @builder.div(class: "diffs show-#{@diff_type}") do
      @builder.table(class: 'unified-diff diff') do
        @builder.colgroup do
          @builder.col(class: 'line-nr')
          @builder.col(class: 'line-nr')
          @builder.col(class: 'output')
        end
        @builder.thead do
          @builder.th(class: 'line-nr', title: I18n.t('submissions.show.your_output')) do
            @builder.i(class: 'mdi mdi-18 mdi-file-account')
          end
          @builder.th(class: 'line-nr', title: I18n.t('submissions.show.expected')) do
            @builder.i(class: 'mdi mdi-18 mdi-file-check')
          end
          @builder.th
        end
        @builder.tbody do
          diff.each do |diff_line|
            if !diff_line[4] && diff_line[3]
              @builder.tr do
                @builder.td(diff_line[1], class: 'line-nr')
                @builder.td(class: 'line-nr')
                @builder.td(class: 'del') do
                  @builder << safe(strip_outer_html(diff_line[3]))
                end
              end
            end
            if !diff_line[4] && diff_line[2]
              @builder.tr do
                @builder.td(class: 'line-nr')
                @builder.td(diff_line[0], class: 'line-nr')
                @builder.td(class: 'ins') do
                  @builder << safe(strip_outer_html(diff_line[2]))
                end
              end
            end
            next unless diff_line[4]

            @builder.tr do
              @builder.td(diff_line[0], class: 'line-nr')
              @builder.td(diff_line[1], class: 'line-nr')
              @builder.td(class: 'unchanged') do
                @builder << safe(strip_outer_html(diff_line[2]))
              end
            end
          end
        end
      end
      @builder.table(class: 'split-diff diff') do
        @builder.colgroup do
          @builder.col(class: 'line-nr')
          @builder.col(class: 'del-output')
          @builder.col(class: 'line-nr')
          @builder.col(class: 'ins-output')
        end
        @builder.thead do
          @builder.th(class: 'line-nr', title: I18n.t('submissions.show.your_output')) do
            @builder.i(class: 'mdi mdi-18 mdi-file-account')
          end
          @builder.th do
            @builder << I18n.t('submissions.show.your_output')
          end
          @builder.th(class: 'line-nr', title: I18n.t('submissions.show.expected')) do
            @builder.i(class: 'mdi mdi-18 mdi-file-check')
          end
          @builder.th do
            @builder << I18n.t('submissions.show.expected')
          end
        end
        @builder.tbody do
          diff.each do |diff_line|
            @builder.tr do
              @builder.td(diff_line[1], class: 'line-nr')
              if !diff_line[4] && diff_line[3]
                @builder.td(class: 'del') do
                  @builder << safe(strip_outer_html(diff_line[3]))
                end
              elsif diff_line[4]
                @builder.td(class: 'unchanged') do
                  @builder << safe(strip_outer_html(diff_line[3]))
                end
              else
                @builder.td
              end
              @builder.td(diff_line[0], class: 'line-nr')
              if !diff_line[4] && diff_line[2]
                @builder.td(class: 'ins') do
                  @builder << safe(strip_outer_html(diff_line[2]))
                end
              elsif diff_line[4]
                @builder.td(class: 'unchanged') do
                  @builder << safe(strip_outer_html(diff_line[3]))
                end
              else
                @builder.td
              end
            end
          end
        end
      end
    end
  end

  def linting(lint_messages, code)
    @builder.div(class: 'linter') do
      source(code, lint_messages.map(&method(:convert_lint_message)))
    end
  end

  def convert_lint_type(type)
    if type.in? %w[fatal error]
      'error'
    elsif type.in? ['warning']
      'warning'
    elsif type.in? %w[refactor convention]
      'info'
    else
      'warning'
    end
  end

  def convert_lint_message(message)
    {
      row: message[:line] - 1,
      type: convert_lint_type(message[:type]),
      text: message[:description]
    }
  end

  def determine_diff_type(test)
    if test[:data][:diff]
      test[:data][:diff].each do |diff_line|
        # Not perfect, since there might be html in the diff_line items
        return 'unified' if !diff_line[2].nil? && strip_outer_html(diff_line[2]).length >= 55
        return 'unified' if !diff_line[3].nil? && strip_outer_html(diff_line[3]).length >= 55
      end
      'split'
    else
      super
    end
  end
end
