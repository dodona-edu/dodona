class CsvDiffer
  require 'builder'

  # Render a table displaying the accepted output
  #
  # @param [Builder::XmlMarkup] builder   The xml builder that is used to generate the html
  # @param [String]             generated The csv-encoded output as received from the judge
  # @return [Builder::XmlMarkup]          Generated table as an xml object
  def self.render_accepted(builder, generated)
    generated = CSV.parse((generated || '').lstrip, nil_value: '')
    gen_headers, *generated = generated

    return if gen_headers.blank?

    builder.div(class: 'diffs') do
      builder.table(class: 'diff csv-diff') do
        builder.colgroup do
          builder.col(class: 'line-nr')
          builder.col(span: gen_headers.length)
        end
        builder.thead do
          builder.tr do
            builder.th(class: 'line-nr')
            builder << gen_headers.map { |el| %(<th>#{CGI.escape_html el}</th>) }.join
          end
        end
        builder.tbody do
          generated.each.with_index do |line, idx|
            builder.tr do
              builder.th(idx + 1, class: 'line-nr')
              builder << line.map { |el| %(<td>#{CGI.escape_html el}</td>) }.join
            end
          end
        end
      end
    end
  end

  # Determine if the numer of columns is lower than 20. Such a table is considered
  # 'renderable' using this differ, otherwise the perfomance penaly might be too high.
  #
  # @param [String] raw The csv-encoded output as received from the judge
  # @return [Boolean]   Is the number of columns 'limited'?
  def self.limited_columns?(raw)
    first_line = raw.lstrip.lines.first
    columncount = CSV.parse_line((first_line || ''), nil_value: '')&.length
    columncount.nil? || columncount <= 20
  end

  # Create a new csv differ, this differ can then be used to create a split and
  # a unified view.
  #
  # The raw csv strings are decoded and the csv header is extracted. If the table
  # has more than 100 rows, a simplified version of the table will be rendered this
  # will limit the performance hit of a very long table.
  #
  # @param [String] generated The csv-encoded generated output as received from the judge
  # @param [String] expected  The csv-encoded expected output as received from the judge
  def initialize(generated, expected)
    @generated = CSV.parse((generated || '').lstrip, nil_value: '')
    @expected = CSV.parse((expected || '').lstrip, nil_value: '')

    @gen_headers, *@generated = @generated
    @gen_headers ||= []
    @exp_headers, *@expected = @expected
    @exp_headers ||= []

    @simplified_table = @generated.length > 100 || @expected.length > 100

    @gen_header_indices, @exp_header_indices, @gen_headers, @exp_headers, @combined_headers = diff_header_indices(@gen_headers, @exp_headers)

    @diff = unless @simplified_table
              Diff::LCS.sdiff(@generated, @expected).map do |chunk|
                gen_result = chunk.old_element || []
                exp_result = chunk.new_element || []
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

  # Render a unified table view based on the data passed when creating the
  # CsvDiffer instance.
  #
  # @return [String] Html string containing the rendered unified table
  def unified
    builder = Builder::XmlMarkup.new
    builder.table(class: 'unified-diff diff csv-diff') do
      builder.colgroup do
        builder.col(class: 'line-nr')
        builder.col(class: 'line-nr')
        builder.col(span: @combined_headers.length)
      end
      builder.thead do
        builder.tr do
          builder.th(class: 'line-nr', title: I18n.t('submissions.show.your_output')) do
            builder.i(class: 'mdi mdi-18 mdi-file-account')
          end
          builder.th(class: 'line-nr', title: I18n.t('submissions.show.expected')) do
            builder.i(class: 'mdi mdi-18 mdi-file-check')
          end
          builder.th(colspan: @combined_headers.length)
        end
        builder.tr do
          builder.th(class: 'line-nr')
          builder.th(class: 'line-nr')
          builder << @combined_headers.join
        end
      end
      builder.tbody do
        if @simplified_table
          unified_simple_body builder
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

  # Render a split table view based on the data passed when creating the
  # CsvDiffer instance.
  #
  # The split view renders two tables, that individually have a horizontal
  # scrollbar.
  #
  # @return [String] Html string containing the rendered split table
  def split
    builder = Builder::XmlMarkup.new

    builder.div do
      split_build_table(builder, @gen_headers, true)
      split_build_table(builder, @exp_headers, false)
    end.html_safe
  end

  private

  # Build one of the two tables of the split table view (see function 'split')
  #
  # @param [Builder::XmlMarkup] builder             The xml builder that is used to generate the html
  # @param [Array<String>]      headers             The csv headers, html encoded and escaped
  # @param [Boolean]            is_generated_output If true, render the generated table; otherwise render the expected table
  # @return [Builder::XmlMarkup]                    The built table as an xml object
  def split_build_table(builder, headers, is_generated_output)
    builder.table(class: 'split-diff diff csv-diff') do
      builder.colgroup do
        builder.col(class: 'line-nr')
        builder.col(span: headers.length)
      end
      builder.thead do
        if is_generated_output
          icon_cls = 'mdi-file-account'
          title = I18n.t('submissions.show.your_output')
        else
          icon_cls = 'mdi-file-check'
          title = I18n.t('submissions.show.expected')
        end
        builder.tr do
          builder.th(class: 'line-nr', title: title) do
            builder.i(class: %(mdi mdi-18 #{icon_cls}))
          end
          builder.th(title, colspan: headers.length)
        end
        builder.tr do
          builder.th(class: 'line-nr')
          builder << headers.join
        end
      end
      builder.tbody do
        if @simplified_table
          if is_generated_output
            split_simple_body(builder, @generated, 'del')
          else
            split_simple_body(builder, @expected, 'ins')
          end
        else
          @diff.each do |chunk|
            builder.tr do
              if is_generated_output
                is_empty, row = old_row(chunk)
                position = chunk.old_position
              else
                is_empty, row = new_row(chunk)
                position = chunk.new_position
              end
              builder << %(<td class="line-nr">#{position + 1 unless is_empty}</td>)
              builder << row.join
            end
          end
        end
      end
    end
  end

  # Build a simplified version of the unified table body
  #
  # This simplified view combines all rows in a column into 1 row with newlines.
  # The columns are still seperate, but the diff is less accurate.
  #
  # @param [Builder::XmlMarkup] builder The xml builder that is used to generate the html
  # @return [Builder::XmlMarkup]        The table contents as an xml object
  def unified_simple_body(builder)
    gen_cols = @generated.transpose.map { |col| col.join("\n") }
    builder.tr do
      builder.td(class: 'line-nr') do
        builder << (1..@generated.length).to_a.join("\n")
      end
      builder.td(class: 'line-nr')

      builder << Array.new(@combined_headers.length) { |i| @gen_header_indices.index(i) }.map do |idx|
        if idx.nil?
          '<td></td>'
        else
          %(<td class="del">#{CGI.escape_html gen_cols[idx]}</td>)
        end
      end.join
    end

    exp_cols = @expected.transpose.map { |col| col.join("\n") }
    builder.tr do
      builder.td(class: 'line-nr')
      builder.td(class: 'line-nr') do
        builder << (1..@expected.length).to_a.join("\n")
      end

      builder << Array.new(@combined_headers.length) { |i| @exp_header_indices.index(i) }.map do |idx|
        if idx.nil?
          '<td></td>'
        else
          %(<td class="ins">#{CGI.escape_html exp_cols[idx]}</td>)
        end
      end.join
    end
  end

  # Build a simplified version of the split table body
  #
  # This simplified view combines all rows in a column into 1 row with newlines.
  # The columns are still seperate, but the diff is less accurate.
  #
  # @param [Builder::XmlMarkup]   builder The xml builder that is used to generate the html
  # @param [Array<Array<String>>] data    The table contents as a decoded (not yet html escaped) 2D array
  # @param [String]               cls     The table td class to use ('ins' or 'del')
  # @return [Builder::XmlMarkup]        The table contents as an xml object
  def split_simple_body(builder, data, cls)
    gen_cols = data.transpose.map { |col| col.join("\n") }

    builder.tr do
      builder.td(class: 'line-nr') do
        builder << (1..data.length).to_a.join("\n")
      end
      gen_cols.each do |col|
        builder.td(class: cls) do
          builder << CGI.escape_html(col)
        end
      end
    end
  end

  # Wrap the row elements (cells) in html td tags. Determine what class to use based on the
  # row chunk action. This way the row will be correctly formatted (eg. green background).
  #
  # @param [Diff::LCS::ContextChange] chunk The result of a LCS sdiff on all the table rows
  # @return [Tuple<Boolean, Array<String>>] Is the mapped class empty, The row with all cells wrapped in a td element
  def old_row(chunk)
    old_class = {
      '-' => 'del',
      '+' => '',
      '=' => 'unchanged',
      '!' => 'del'
    }[chunk.action]
    [old_class.empty?, chunk.old_element.map { |el| %(<td class="#{old_class}">#{el}</td>) }]
  end

  # Wrap the row elements (cells) in html td tags. Determine what class to use based on the
  # row chunk action. This way the row will be correctly formatted (eg. green background).
  #
  # @param [Diff::LCS::ContextChange] chunk The result of a LCS sdiff on all the table rows
  # @return [Tuple<Boolean, Array<String>>] Is the mapped class empty, The row with all cells wrapped in a td element
  def new_row(chunk)
    new_class = {
      '-' => '',
      '+' => 'ins',
      '=' => 'unchanged',
      '!' => 'ins'
    }[chunk.action]
    [new_class.empty?, chunk.new_element.map { |el| %(<td class="#{new_class}">#{el}</td>) }]
  end

  # Calculate the differences between two arrays (rows) an enclose these differences
  # in strong html tags. Also, html escape the raw table data before enclosing.
  #
  # @param [Array<String>] generated    A generated row, csv decoded but not yet html escaped
  # @param [Array<String>] expected     An expected row, csv decoded but not yet html escaped
  # @return [Tuple<Array<String>, Array<String>>] The escaped html diff arrays
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

  # Compare the table headers of the generated and expected table.
  #
  # The combined headers is the minimal set of headers that include the
  # generated and expected headers (including duplicates). The indices
  # arrays can be used to map the original input headers to the correct
  # headers in the combined header list.
  #
  # @param [Array<String>] generated    The generated headers, csv decoded but not yet html escaped
  # @param [Array<String>] expected     The expected headers, csv decoded but not yet html escaped
  # @return [Tuple<Array<Integer>, Array<Integer>, Array<String>, Array<String>, Array<String>>]
  #   0: gen_indices Locations of the generated headers in the combined_headers array
  #   1: exp_indices Locations of the expected headers in the combined_headers array
  #   2: gen_headers The escaped generated header html array
  #   3: exp_headers The escaped expected header html array
  #   4: combined_headers The escaped combined html diff arrays
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
