class LCSHtmlDiffer

  require 'builder'

  def initialize(generated, expected)
    @diff = Diff::LCS.sdiff(generated&.split("\n", -1) || [], expected&.split("\n", -1) || [])
    @builder = Builder::XmlMarkup.new
  end

  def unified
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
        @builder.th(class: 'line-nr', title: I18n.t("submissions.show.expected")) do
          @builder.i(class: 'mdi mdi-18 mdi-file-check')
        end
        @builder.th
      end
      @builder.tbody do
        @diff.each do |chunk|
          case chunk.action
          when "-"
            @builder.tr do
              @builder.td(class: 'line-nr') do
                @builder << (chunk.old_position + 1).to_s
              end
              @builder.td(class: 'line-nr')
              @builder.td(class: 'del') do
                @builder << CGI::escape_html(chunk.old_element)
              end
            end
          when "+"
            @builder.tr do
              @builder.td(class: 'line-nr')
              @builder.td(class: 'line-nr') do
                @builder << (chunk.new_position + 1).to_s
              end
              @builder.td(class: 'ins') do
                @builder << CGI::escape_html(chunk.new_element)
              end
            end
          when "="
            @builder.tr do
              @builder.td(class: 'line-nr') do
                @builder << (chunk.old_position + 1).to_s
              end
              @builder.td(class: 'line-nr') do
                @builder << (chunk.new_position + 1).to_s
              end
              @builder.td(class: 'unchanged') do
                @builder << CGI::escape_html(chunk.old_element)
              end
            end
          when "!"
            gen_result, exp_result = diff_strings(chunk.old_element, chunk.new_element)
            @builder.tr do
              @builder.td(class: 'line-nr') do
                @builder << (chunk.old_position + 1).to_s
              end
              @builder.td(class: 'line-nr')
              @builder.td(class: 'del') do
                @builder << gen_result
              end
            end
            @builder.tr do
              @builder.td(class: 'line-nr')
              @builder.td(class: 'line-nr') do
                @builder << (chunk.new_position + 1).to_s
              end
              @builder.td(class: 'ins') do
                @builder << exp_result
              end
            end
          end
        end
        nil
      end
    end.html_safe
  end

  def split
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
        @builder.th(class: 'line-nr', title: I18n.t("submissions.show.expected")) do
          @builder.i(class: 'mdi mdi-18 mdi-file-check')
        end
        @builder.th do
          @builder << I18n.t("submissions.show.expected")
        end
      end
      @builder.tbody do
        @diff.each do |chunk|
          case chunk.action
          when "-"
            @builder.tr do
              @builder.td(class: 'line-nr') do
                @builder << (chunk.old_position + 1).to_s
              end
              @builder.td(class: 'del') do
                @builder << CGI::escape_html(chunk.old_element)
              end
              @builder.td(class: 'line-nr')
              @builder.td
            end
          when "+"
            @builder.tr do
              @builder.td(class: 'line-nr')
              @builder.td
              @builder.td(class: 'line-nr') do
                @builder << (chunk.new_position + 1).to_s
              end
              @builder.td(class: 'ins') do
                @builder << CGI::escape_html(chunk.new_element)
              end
            end
          when "="
            @builder.tr do
              @builder.td(class: 'line-nr') do
                @builder << (chunk.old_position + 1).to_s
              end
              @builder.td(class: 'unchanged') do
                @builder << CGI::escape_html(chunk.old_element)
              end
              @builder.td(class: 'line-nr') do
                @builder << (chunk.new_position + 1).to_s
              end
              @builder.td(class: 'unchanged') do
                @builder << CGI::escape_html(chunk.new_element)
              end
            end
          when "!"
            gen_result, exp_result = diff_strings(chunk.old_element, chunk.new_element)
            @builder.tr do
              @builder.td(class: 'line-nr') do
                @builder << (chunk.old_position + 1).to_s
              end
              @builder.td(class: 'del') do
                @builder << gen_result
              end
              @builder.td(class: 'line-nr') do
                @builder << (chunk.new_position + 1).to_s
              end
              @builder.td(class: 'ins') do
                @builder << exp_result
              end
            end
          end
        end
        nil
      end
    end.html_safe
  end

  private

  def diff_strings(generated, expected)
    return [generated, expected] if generated.length > 200 || expected.length > 200
    exp_result = ""
    gen_result = ""
    in_exp_strong = false
    in_gen_strong = false
    Diff::LCS.sdiff(generated, expected) do |chunk|
      case chunk.action
      when "-"
        unless in_gen_strong
          gen_result += "<strong>"
          in_gen_strong = true
        end
        gen_result += CGI::escape_html chunk.old_element
      when "+"
        unless in_exp_strong
          exp_result += "<strong>"
          in_exp_strong = true
        end
        exp_result += CGI::escape_html chunk.new_element
      when "="
        if in_gen_strong
          gen_result += "</strong>"
          in_gen_strong = false
        end
        if in_exp_strong
          exp_result += "</strong>"
          in_exp_strong = false
        end
        gen_result += CGI::escape_html chunk.old_element
        exp_result += CGI::escape_html chunk.new_element
      when "!"
        unless in_gen_strong
          gen_result += "<strong>"
          in_gen_strong = true
        end
        unless in_exp_strong
          exp_result += "<strong>"
          in_exp_strong = true
        end
        gen_result += CGI::escape_html chunk.old_element
        exp_result += CGI::escape_html chunk.new_element
      end
    end
    if in_gen_strong
      gen_result += "</strong>"
    end
    if in_exp_strong
      exp_result += "</strong>"
    end
    [gen_result, exp_result]
  end
end
