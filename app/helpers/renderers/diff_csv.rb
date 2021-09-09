class DiffCsv
  require 'builder'

  def self.render_accepted(builder, generated)
    generated = generated.lstrip || ''
    gen_headers, generated = generated.split("\n", 2)
    gen_headers = gen_headers.nil? ? [] : CSV.parse_line(gen_headers)
    gen_headers = gen_headers.map { |el| el.nil? ? '' : el }
    generated ||= ''

    return if gen_headers.empty?

    builder.div(class: 'diffs show-unified') do
      builder.table(class: 'unified-diff diff csv-diff') do
        builder.colgroup do
          builder.col(class: 'line-nr')
          builder.col(class: 'del-output-csv', span: gen_headers.length)
        end
        builder.thead do
          builder.tr do
            builder << "<th class='line-nr'></th>"
            builder << gen_headers.map { |el| %(<th>#{CGI.escape_html el}</th>) }.join
          end
        end
        builder.tbody do
          generated.split("\n", -1).each.with_index do |line, idx|
            builder.tr do
              builder << %(<td class="line-nr">#{idx + 1}</td>)
              builder << (CSV.parse_line(line || '') || Array.new(gen_headers.length) { '' }).map { |el| %(<td>#{CGI.escape_html el || ''}</td>) }.join
            end
          end
        end
      end
    end
  end

  def initialize(generated, expected)
    extract_headers = lambda { |text|
      text = text.lstrip || ''
      headers, text = text.split("\n", 2)
      headers = headers.nil? ? [] : CSV.parse_line(headers)
      headers = headers.map { |el| el.nil? ? '' : el }
      text ||= ''
      [headers, text]
    }

    @gen_headers, @generated = extract_headers.call(generated)
    @exp_headers, @expected = extract_headers.call(expected)

    @generated_linecount = @generated&.lines&.count || 0
    @expected_linecount = @expected&.lines&.count || 0
    @simplified_table = @generated_linecount > 100 || @expected_linecount > 100

    @gen_header_indices, @exp_header_indices, @gen_headers, @exp_headers, @combined_headers = diff_header_indices(@gen_headers, @exp_headers)

    @diff = unless @simplified_table
              csv_text_to_array = lambda { |csv_text, header_length|
                (
                  CSV.parse_line(csv_text || '') ||  # parse the line (if no old_element is set, parse '')
                  Array.new(header_length) { '' }    # if the parsed line returns nil, use an array with empty values instead
                ).map { |el| el.nil? ? '' : el }     # replace all nil values with ''
              }
              Diff::LCS.sdiff(@generated.split("\n", -1), @expected.split("\n", -1)).map do |chunk|
                gen_result = csv_text_to_array.call(chunk.old_element, @gen_headers.length)
                exp_result = csv_text_to_array.call(chunk.new_element, @exp_headers.length)
                if chunk.action == '!'
                  gen_result, exp_result = diff_arrays(gen_result, exp_result)
                else
                  gen_result = gen_result.map { |el| CGI.escape_html el }
                  exp_result = exp_result.map { |el| CGI.escape_html el }
                end
                Diff::LCS::ContextChange.new(chunk.action, chunk.old_position, gen_result, chunk.new_position, exp_result)
              end
            end
  end

  def unified
    builder = Builder::XmlMarkup.new
    builder.table(class: "unified-diff diff csv-diff #{@simplified_table ? 'simplified' : ''}") do
      builder.colgroup do
        builder.col(class: 'line-nr')
        builder.col(class: 'line-nr')
        builder.col(class: 'output-csv', span: @combined_headers.length)
      end
      builder.thead do
        builder.tr do
          builder << "<th class='line-nr' title='#{I18n.t('submissions.show.your_output')}'><i class='mdi mdi-18 mdi-file-account'/></th>"
          builder << "<th class='line-nr' title='#{I18n.t('submissions.show.expected')}'><i class='mdi mdi-18 mdi-file-check'/></th>"
          builder << "<th colspan='#{@combined_headers.length}'>#{I18n.t('submissions.show.your_output')}</th>"
        end
        builder.tr do
          builder << "<th class='line-nr'></th>"
          builder << "<th class='line-nr'></th>"
          builder << @combined_headers.join
        end
      end
      builder.tbody do
        if @simplified_table
          unified_simple builder
        else
          @diff.each do |chunk|
            is_empty, row = old_row chunk

            unless is_empty
              full_row = Array.new(@combined_headers.length) { |i| @gen_header_indices.index(i) }.map { |idx| idx.nil? ? '<td></td>' : row[idx] }

              builder << %(<tr>
              <td class="line-nr">#{chunk.old_position + 1}</td>
              <td class="line-nr"></td>
              #{full_row.join}
            </tr>)
            end

            is_empty, row = new_row chunk

            next if is_empty

            full_row = Array.new(@combined_headers.length) { |i| @exp_header_indices.index(i) }.map { |idx| idx.nil? ? '<td></td>' : row[idx] }

            builder << %(<tr>
              <td class="line-nr"></td>
              <td class="line-nr">#{chunk.new_position + 1}</td>
              #{full_row.join}
            </tr>)
          end
        end
      end
    end.html_safe
  end

  def split
    builder = Builder::XmlMarkup.new

    builder.div do
      build_table = lambda { |headers, is_old, cls, icon_cls, title|
        builder.table(class: "split-diff diff csv-diff #{@simplified_table ? 'simplified' : ''}") do
          builder.colgroup do
            builder.col(class: 'line-nr')
            builder.col(class: cls, span: headers.length)
          end
          builder.thead do
            builder.tr do
              builder << "<th class='line-nr' title='#{title}'><i class='mdi mdi-18 #{icon_cls}'/></th>"
              builder << "<th colspan='#{headers.length}'>#{title}</th>"
            end
            builder.tr do
              builder << "<th class='line-nr'></th>"
              builder << headers.join
            end
          end
          builder.tbody do
            if @simplified_table
              method(is_old ? :simple_old_row : :simple_new_row).call(builder)
            else
              @diff.each do |chunk|
                builder.tr do
                  is_empty, row = method(is_old ? :old_row : :new_row).call(chunk)
                  position = is_old ? chunk.old_position : chunk.new_position
                  builder << %(<td class="line-nr">#{position + 1 unless is_empty}</td>)
                  builder << row.join
                end
              end
            end
          end
        end
      }

      build_table.call(@gen_headers, true, 'del-output-csv', 'mdi-file-account', I18n.t('submissions.show.your_output'))
      build_table.call(@exp_headers, false, 'ins-output-csv', 'mdi-file-check', I18n.t('submissions.show.expected'))
    end.html_safe
  end

  private

  def unified_simple(builder)
    gen_cols = CSV.parse(@generated).transpose.map { |col| col.join("\n") }
    builder.tr do
      builder.td(class: 'line-nr') do
        builder << (1..@generated_linecount).to_a.join("\n")
      end
      builder.td(class: 'line-nr')

      builder << Array.new(@combined_headers.length) { |i| @gen_header_indices.index(i) }.map { |idx| idx.nil? ? '<td></td>' : %(<td class="del">#{CGI.escape_html gen_cols[idx]}</td>) }.join
    end

    exp_cols = CSV.parse(@expected).transpose.map { |col| col.join("\n") }
    builder.tr do
      builder.td(class: 'line-nr')
      builder.td(class: 'line-nr') do
        builder << (1..@expected_linecount).to_a.join("\n")
      end

      builder << Array.new(@combined_headers.length) { |i| @exp_header_indices.index(i) }.map { |idx| idx.nil? ? '<td></td>' : %(<td class="ins">#{CGI.escape_html exp_cols[idx]}</td>) }.join
    end
  end

  def simple_old_row(builder)
    gen_cols = CSV.parse(@generated).transpose.map { |col| col.join("\n") }

    builder.tr do
      builder.td(class: 'line-nr') do
        builder << (1..@generated_linecount).to_a.join("\n")
      end
      gen_cols.each do |col|
        builder.td(class: 'del') do
          builder << CGI.escape_html(col)
        end
      end
    end
  end

  def simple_new_row(builder)
    exp_cols = CSV.parse(@expected).transpose.map { |col| col.join("\n") }

    builder.tr do
      builder.td(class: 'line-nr') do
        builder << (1..@expected_linecount).to_a.join("\n")
      end
      exp_cols.each do |col|
        builder.td(class: 'ins') do
          builder << CGI.escape_html(col)
        end
      end
    end
  end

  def old_row(chunk)
    old_class = {
      '-' => 'del',
      '+' => '',
      '=' => 'unchanged',
      '!' => 'del'
    }[chunk.action]
    [old_class.empty?, chunk.old_element.map { |el| %(<td class="#{old_class}">#{el}</td>) }]
  end

  def new_row(chunk)
    new_class = {
      '-' => '',
      '+' => 'ins',
      '=' => 'unchanged',
      '!' => 'ins'
    }[chunk.action]
    [new_class.empty?, chunk.new_element.map { |el| %(<td class="#{new_class}">#{el}</td>) }]
  end

  def diff_arrays(generated, expected)
    gen_result = []
    exp_result = []
    Diff::LCS.sdiff(generated, expected) do |chunk|
      case chunk.action
      when '-'
        gen_result << %(<strong>#{CGI.escape_html chunk.old_element}</strong>)
      when '+'
        exp_result << %(<strong>#{CGI.escape_html chunk.new_element}</strong>)
      when '='
        gen_result << (CGI.escape_html chunk.old_element)
        exp_result << (CGI.escape_html chunk.new_element)
      when '!'
        gen_result << %(<strong>#{CGI.escape_html chunk.old_element}</strong>)
        exp_result << %(<strong>#{CGI.escape_html chunk.new_element}</strong>)
      end
    end
    [gen_result, exp_result]
  end

  def diff_header_indices(generated, expected)
    counter = 0
    gen_indices = []
    exp_indices = []

    gen_headers = []
    exp_headers = []

    combined_headers = []

    Diff::LCS.sdiff(generated, expected) do |chunk|
      case chunk.action
      when '-'
        gen_indices << counter
        counter += 1
        gen_headers << %(<th class="del"><strong>#{CGI.escape_html chunk.old_element}</strong></th>)
        combined_headers << %(<th class="del"><strong>#{CGI.escape_html chunk.old_element}</strong></th>)
      when '+'
        exp_indices << counter
        counter += 1
        exp_headers << %(<th class="ins"><strong>#{CGI.escape_html chunk.new_element}</strong></th>)
        combined_headers << %(<th class="ins"><strong>#{CGI.escape_html chunk.new_element}</strong></th>)
      when '='
        gen_indices << counter
        exp_indices << counter
        counter += 1
        gen_headers << %(<th>#{CGI.escape_html chunk.old_element}</th>)
        exp_headers << %(<th>#{CGI.escape_html chunk.new_element}</th>)
        combined_headers << %(<th>#{CGI.escape_html chunk.new_element}</th>)
      when '!'
        gen_indices << counter
        counter += 1
        gen_headers << %(<th class="del"><strong>#{CGI.escape_html chunk.old_element}</strong></th>)
        combined_headers << %(<th class="del"><strong>#{CGI.escape_html chunk.old_element}</strong></th>)

        exp_indices << counter
        counter += 1
        exp_headers << %(<th class="ins"><strong>#{CGI.escape_html chunk.new_element}</strong></th>)
        combined_headers << %(<th class="ins"><strong>#{CGI.escape_html chunk.new_element}</strong></th>)
      end
    end
    [gen_indices, exp_indices, gen_headers, exp_headers, combined_headers]
  end
end
