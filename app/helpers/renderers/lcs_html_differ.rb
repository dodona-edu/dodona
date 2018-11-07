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
    @builder.table(class: 'splitt-diff diff') do
      @builder.colgroup do
        @builder.col(class: 'line-nr')
        @builder.col(class: 'del-output')
        @builder.col(class: 'line-nr')
        @builder.col(class: 'ins-output')
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
    exp_result = ""
    gen_result = ""
    Diff::LCS.sdiff(generated, expected) do |chunk|
      case chunk.action
      when "-"
        gen_result += "<strong>#{CGI::escape_html chunk.old_element}</strong>"
      when "+"
        exp_result += "<strong>#{CGI::escape_html chunk.new_element}</strong>"
      when "="
        gen_result += CGI::escape_html chunk.old_element
        exp_result += CGI::escape_html chunk.new_element
      when "!"
        gen_result += "<strong>#{CGI::escape_html chunk.old_element}</strong>"
        exp_result += "<strong>#{CGI::escape_html chunk.new_element}</strong>"
      end
    end
    [gen_result, exp_result]
  end
end
