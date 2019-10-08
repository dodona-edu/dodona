class LCSHtmlDiffer
  require 'builder'

  def initialize(generated, expected)
    @generated = generated || ''
    @expected = expected || ''
    @generated_linecount = generated&.lines&.count || 0
    @expected_linecount = expected&.lines&.count || 0
    @simplified_table = @generated_linecount > 200 || @expected_linecount > 200
    @diff = unless @simplified_table
              Diff::LCS.sdiff(@generated.split("\n", -1), @expected.split("\n", -1)).map do |chunk|
                if chunk.action == '!'
                  gen_result, exp_result = diff_strings(chunk.old_element, chunk.new_element)
                  Diff::LCS::ContextChange.new('!', chunk.old_position, gen_result, chunk.new_position, exp_result)
                else
                  chunk
                end
              end
            end
  end

  def unified
    builder = Builder::XmlMarkup.new
    builder.table(class: 'unified-diff diff') do
      builder.colgroup do
        builder.col(class: 'line-nr')
        builder.col(class: 'line-nr')
        builder.col(class: 'output')
      end
      builder.thead do
        builder.th(class: 'line-nr', title: I18n.t('submissions.show.your_output')) do
          builder.i(class: 'mdi mdi-18 mdi-file-account')
        end
        builder.th(class: 'line-nr', title: I18n.t('submissions.show.expected')) do
          builder.i(class: 'mdi mdi-18 mdi-file-check')
        end
        builder.th
      end
      builder.tbody do
        if @simplified_table
          unified_simple builder
        else
          @diff.each do |chunk|
            unified_chunk builder, chunk
          end
        end
        nil
      end
    end.html_safe
  end

  def split
    builder = Builder::XmlMarkup.new
    builder.table(class: 'split-diff diff') do
      builder.colgroup do
        builder.col(class: 'line-nr')
        builder.col(class: 'del-output')
        builder.col(class: 'line-nr')
        builder.col(class: 'ins-output')
      end
      builder.thead do
        builder.th(class: 'line-nr', title: I18n.t('submissions.show.your_output')) do
          builder.i(class: 'mdi mdi-18 mdi-file-account')
        end
        builder.th do
          builder << I18n.t('submissions.show.your_output')
        end
        builder.th(class: 'line-nr', title: I18n.t('submissions.show.expected')) do
          builder.i(class: 'mdi mdi-18 mdi-file-check')
        end
        builder.th do
          builder << I18n.t('submissions.show.expected')
        end
      end
      builder.tbody do
        if @simplified_table
          split_simple builder
        else
          @diff.each do |chunk|
            split_chunk builder, chunk
          end
        end
        nil
      end
    end.html_safe
  end

  private

  def unified_simple(builder)
    builder.tr do
      builder.td(class: 'line-nr') do
        builder << (1..@generated_linecount).to_a.join("\n")
      end
      builder.td(class: 'line-nr')
      builder.td(class: 'del') do
        builder << CGI.escape_html(@generated)
      end
    end
    builder.tr do
      builder.td(class: 'line-nr')
      builder.td(class: 'line-nr') do
        builder << (1..@expected_linecount).to_a.join("\n")
      end
      builder.td(class: 'ins') do
        builder << CGI.escape_html(@expected)
      end
    end
  end

  def unified_chunk(builder, chunk)
    case chunk.action
    when '-'
      builder.tr do
        builder.td(class: 'line-nr') do
          builder << (chunk.old_position + 1).to_s
        end
        builder.td(class: 'line-nr')
        builder.td(class: 'del') do
          builder << CGI.escape_html(chunk.old_element)
        end
      end
    when '+'
      builder.tr do
        builder.td(class: 'line-nr')
        builder.td(class: 'line-nr') do
          builder << (chunk.new_position + 1).to_s
        end
        builder.td(class: 'ins') do
          builder << CGI.escape_html(chunk.new_element)
        end
      end
    when '='
      builder.tr do
        builder.td(class: 'line-nr') do
          builder << (chunk.old_position + 1).to_s
        end
        builder.td(class: 'line-nr') do
          builder << (chunk.new_position + 1).to_s
        end
        builder.td(class: 'unchanged') do
          builder << CGI.escape_html(chunk.old_element)
        end
      end
    when '!'
      # The new_element and old_element fields have been preprocessed
      # in the constructor and therefore don't need to be escaped.
      builder.tr do
        builder.td(class: 'line-nr') do
          builder << (chunk.old_position + 1).to_s
        end
        builder.td(class: 'line-nr')
        builder.td(class: 'del') do
          builder << chunk.old_element
        end
      end
      builder.tr do
        builder.td(class: 'line-nr')
        builder.td(class: 'line-nr') do
          builder << (chunk.new_position + 1).to_s
        end
        builder.td(class: 'ins') do
          builder << chunk.new_element
        end
      end
    end
  end

  def split_simple(builder)
    builder.tr do
      builder.td(class: 'line-nr') do
        builder << (1..@generated_linecount).to_a.join("\n")
      end
      builder.td(class: 'del') do
        builder << CGI.escape_html(@generated)
      end
      builder.td(class: 'line-nr') do
        builder << (1..@expected_linecount).to_a.join("\n")
      end
      builder.td(class: 'ins') do
        builder << CGI.escape_html(@expected)
      end
    end
  end

  def split_chunk(builder, chunk)
    case chunk.action
    when '-'
      builder.tr do
        builder.td(class: 'line-nr') do
          builder << (chunk.old_position + 1).to_s
        end
        builder.td(class: 'del') do
          builder << CGI.escape_html(chunk.old_element)
        end
        builder.td(class: 'line-nr')
        builder.td
      end
    when '+'
      builder.tr do
        builder.td(class: 'line-nr')
        builder.td
        builder.td(class: 'line-nr') do
          builder << (chunk.new_position + 1).to_s
        end
        builder.td(class: 'ins') do
          builder << CGI.escape_html(chunk.new_element)
        end
      end
    when '='
      builder.tr do
        builder.td(class: 'line-nr') do
          builder << (chunk.old_position + 1).to_s
        end
        builder.td(class: 'unchanged') do
          builder << CGI.escape_html(chunk.old_element)
        end
        builder.td(class: 'line-nr') do
          builder << (chunk.new_position + 1).to_s
        end
        builder.td(class: 'unchanged') do
          builder << CGI.escape_html(chunk.new_element)
        end
      end
    when '!'
      # The new_element and old_element fields have been preprocessed
      # in the constructor and therefore don't need to be escaped.
      builder.tr do
        builder.td(class: 'line-nr') do
          builder << (chunk.old_position + 1).to_s
        end
        builder.td(class: 'del') do
          builder << chunk.old_element
        end
        builder.td(class: 'line-nr') do
          builder << (chunk.new_position + 1).to_s
        end
        builder.td(class: 'ins') do
          builder << chunk.new_element
        end
      end
    end
  end

  def diff_strings(generated, expected)
    return [CGI.escape_html(generated), CGI.escape_html(expected)] if generated.length > 100 || expected.length > 100

    exp_result = ''
    gen_result = ''
    in_exp_strong = false
    in_gen_strong = false
    Diff::LCS.sdiff(generated, expected) do |chunk|
      case chunk.action
      when '-'
        unless in_gen_strong
          gen_result += '<strong>'
          in_gen_strong = true
        end
        gen_result += CGI.escape_html chunk.old_element
      when '+'
        unless in_exp_strong
          exp_result += '<strong>'
          in_exp_strong = true
        end
        exp_result += CGI.escape_html chunk.new_element
      when '='
        if in_gen_strong
          gen_result += '</strong>'
          in_gen_strong = false
        end
        if in_exp_strong
          exp_result += '</strong>'
          in_exp_strong = false
        end
        gen_result += CGI.escape_html chunk.old_element
        exp_result += CGI.escape_html chunk.new_element
      when '!'
        unless in_gen_strong
          gen_result += '<strong>'
          in_gen_strong = true
        end
        unless in_exp_strong
          exp_result += '<strong>'
          in_exp_strong = true
        end
        gen_result += CGI.escape_html chunk.old_element
        exp_result += CGI.escape_html chunk.new_element
      end
    end
    gen_result += '</strong>' if in_gen_strong
    exp_result += '</strong>' if in_exp_strong
    [gen_result, exp_result]
  end
end
