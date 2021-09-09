require 'test_helper'

class DiffCsvTest < ActiveSupport::TestCase
  require 'builder'
  require 'nokogiri'

  setup do
  end

  def should_match_html(exp, act)
    dom1 = Nokogiri::XML(exp, &:noblanks)
    dom2 = Nokogiri::XML(act, &:noblanks)
    assert_equal dom1.to_s, dom2.to_s
  end

  def html_output(a_headers, a_body, b_headers, b_body, is_simplified = false)
    <<~HTML
      <div>
          <table class="split-diff diff csv-diff #{is_simplified ? 'simplified' : ''}">
              <colgroup>
                  <col class="line-nr"/>
                  <col class="del-output-csv" span="#{a_headers.length}"/>
              </colgroup>
              <thead>
                  <tr>
                      <th class='line-nr' title='Jouw uitvoer'><i class='mdi mdi-18 mdi-file-account'/></th>
                      <th colspan='#{a_headers.length}'>Jouw uitvoer</th>
                  </tr>
                  <tr>
                      <th class='line-nr'></th>
                      #{a_headers.join}
                  </tr>
              </thead>
                  #{
                    if a_body.empty?
                      %(<tbody/>)
                    else
                      %(<tbody>#{a_body.map { |el| %(<tr>#{el}</tr>) }.join}</tbody>)
                    end
                  }
          </table>
          <table class="split-diff diff csv-diff #{is_simplified ? 'simplified' : ''}">
              <colgroup>
                  <col class="line-nr"/>
                  <col class="ins-output-csv" span="#{b_headers.length}"/>
              </colgroup>
              <thead>
                  <tr>
                      <th class='line-nr' title='Verwachte uitvoer'><i class='mdi mdi-18 mdi-file-check'/></th>
                      <th colspan='#{b_headers.length}'>Verwachte uitvoer</th>
                  </tr>
                  <tr>
                      <th class='line-nr'></th>
                      #{b_headers.join}
                  </tr>
              </thead>
              #{
                if b_body.empty?
                  %(<tbody/>)
                else
                  %(<tbody>#{b_body.map { |el| %(<tr>#{el}</tr>) }.join}</tbody>)
                end
              }
          </table>
      </div>
    HTML
  end

  test 'content and headers fully wrong' do
    generated = <<~EOS.chomp
      "AAA","AAA"
      "BBB","BBB"
      "CCC","CCC"
    EOS
    expected = <<~EOS.chomp
      "BBB","BBB"
      "AAA","AAA"
      "AAA","AAA"
    EOS

    diff_csv = DiffCsv.new(generated, expected)

    diff = html_output(
      [
        %(<th class="del"><strong>AAA</strong></th>),
        %(<th class="del"><strong>AAA</strong></th>)
      ],
      [
        %(<td class="line-nr">1</td><td class="del"><strong>BBB</strong></td><td class="del"><strong>BBB</strong></td>),
        %(<td class="line-nr">2</td><td class="del"><strong>CCC</strong></td><td class="del"><strong>CCC</strong></td>)
      ],
      [
        %(<th class="ins"><strong>BBB</strong></th>),
        %(<th class="ins"><strong>BBB</strong></th>)
      ],
      [
        %(<td class="line-nr">1</td><td class="ins"><strong>AAA</strong></td><td class="ins"><strong>AAA</strong></td>),
        %(<td class="line-nr">2</td><td class="ins"><strong>AAA</strong></td><td class="ins"><strong>AAA</strong></td>)
      ]
    )
    should_match_html diff, diff_csv.split
  end

  test 'empty header' do
    generated = <<~EOS.chomp
    EOS
    expected = <<~EOS.chomp
      "BBB","BBB"
      "AAA","AAA"
      "AAA","AAA"
    EOS

    diff_csv = DiffCsv.new(generated, expected)

    diff = html_output(
      [],
      [
        %(<td class="line-nr"></td>),
        %(<td class="line-nr"></td>)
      ],
      [
        %(<th class="ins"><strong>BBB</strong></th>),
        %(<th class="ins"><strong>BBB</strong></th>)
      ],
      [
        %(<td class="line-nr">1</td><td class="ins">AAA</td><td class="ins">AAA</td>),
        %(<td class="line-nr">2</td><td class="ins">AAA</td><td class="ins">AAA</td>)
      ]
    )
    should_match_html diff, diff_csv.split
  end

  test 'empty body' do
    generated = <<~EOS.chomp
      "AAA","AAA"
    EOS
    expected = <<~EOS.chomp
      "BBB","BBB"
    EOS

    diff_csv = DiffCsv.new(generated, expected)

    diff = html_output(
      [
        %(<th class="del"><strong>AAA</strong></th>),
        %(<th class="del"><strong>AAA</strong></th>)
      ],
      [],
      [
        %(<th class="ins"><strong>BBB</strong></th>),
        %(<th class="ins"><strong>BBB</strong></th>)
      ],
      []
    )
    should_match_html diff, diff_csv.split
  end

  test 'starting newline' do
    generated = <<~EOS.chomp

      "AAA","AAA"
      "BBB","BBB"
      "CCC","CCC"
    EOS
    expected = <<~EOS.chomp
      "BBB","BBB"
      "AAA","AAA"
      "AAA","AAA"
    EOS

    diff_csv = DiffCsv.new(generated, expected)

    diff = html_output(
      [
        %(<th class="del"><strong>AAA</strong></th>),
        %(<th class="del"><strong>AAA</strong></th>)
      ],
      [
        %(<td class="line-nr">1</td><td class="del"><strong>BBB</strong></td><td class="del"><strong>BBB</strong></td>),
        %(<td class="line-nr">2</td><td class="del"><strong>CCC</strong></td><td class="del"><strong>CCC</strong></td>)
      ],
      [
        %(<th class="ins"><strong>BBB</strong></th>),
        %(<th class="ins"><strong>BBB</strong></th>)
      ],
      [
        %(<td class="line-nr">1</td><td class="ins"><strong>AAA</strong></td><td class="ins"><strong>AAA</strong></td>),
        %(<td class="line-nr">2</td><td class="ins"><strong>AAA</strong></td><td class="ins"><strong>AAA</strong></td>)
      ]
    )
    should_match_html diff, diff_csv.split
  end

  test 'trailing newline' do
    generated = <<~EOS.chomp
      "AAA","AAA"
      "BBB","BBB"
    EOS
    expected = <<~EOS.chomp
      "BBB","BBB"
      "AAA","AAA"
      #{''}
    EOS

    diff_csv = DiffCsv.new(generated, expected)

    diff = html_output(
      [
        %(<th class="del"><strong>AAA</strong></th>),
        %(<th class="del"><strong>AAA</strong></th>)
      ],
      [
        %(<td class="line-nr">1</td><td class="del"><strong>BBB</strong></td><td class="del"><strong>BBB</strong></td>),
        %(<td class="line-nr"></td><td class=""></td><td class=""></td>)
      ],
      [
        %(<th class="ins"><strong>BBB</strong></th>),
        %(<th class="ins"><strong>BBB</strong></th>)
      ],
      [
        %(<td class="line-nr">1</td><td class="ins"><strong>AAA</strong></td><td class="ins"><strong>AAA</strong></td>),
        %(<td class="line-nr">2</td><td class="ins"></td><td class="ins"></td>)
      ]
    )
    should_match_html diff, diff_csv.split
  end

  test 'nil value and nil line' do
    generated = <<~EOS.chomp
      "BBB",,"BBB"

      "BBB","BBB","BBB"
    EOS
    expected = <<~EOS.chomp
      "BBB","AAA","BBB"
      "AAA","AAA","AAA"
      "AAA","AAA","AAA"
    EOS

    diff_csv = DiffCsv.new(generated, expected)

    diff = html_output(
      [
        %(<th>BBB</th>),
        %(<th class="del"><strong/></th>),
        %(<th>BBB</th>)
      ],
      [
        %(<td class="line-nr">1</td><td class="del"><strong/></td><td class="del"><strong/></td><td class="del"><strong/></td>),
        %(<td class="line-nr">2</td><td class="del"><strong>BBB</strong></td><td class="del"><strong>BBB</strong></td><td class="del"><strong>BBB</strong></td>)
      ],
      [
        %(<th>BBB</th>),
        %(<th class="ins"><strong>AAA</strong></th>),
        %(<th>BBB</th>)
      ],
      [
        %(<td class="line-nr">1</td><td class="ins"><strong>AAA</strong></td><td class="ins"><strong>AAA</strong></td><td class="ins"><strong>AAA</strong></td>),
        %(<td class="line-nr">2</td><td class="ins"><strong>AAA</strong></td><td class="ins"><strong>AAA</strong></td><td class="ins"><strong>AAA</strong></td>)
      ]
    )
    should_match_html diff, diff_csv.split
  end

  test 'nearly simplified view' do
    nr_rows = 100
    nr_columns = 100
    csv_string1 = CSV.generate do |csv|
      (nr_rows + 1).times { |_i| csv << ['AAA'] * nr_columns }
    end

    csv_string2 = CSV.generate do |csv|
      (nr_rows + 1).times { |_i| csv << ['BBB'] * nr_columns }
    end

    diff_csv = DiffCsv.new(csv_string1.chomp, csv_string2.chomp)

    diff = html_output(
      [
        %(<th class="del"><strong>AAA</strong></th>)
      ] * nr_columns,
      (1..nr_rows).map do |i|
        %(<td class="line-nr">#{i}</td>) + %(<td class="del"><strong>AAA</strong></td>) * nr_columns
      end,
      [
        %(<th class="ins"><strong>BBB</strong></th>)
      ] * nr_columns,
      (1..nr_rows).map do |i|
        %(<td class="line-nr">#{i}</td>) + %(<td class="ins"><strong>BBB</strong></td>) * nr_columns
      end
    )
    should_match_html diff, diff_csv.split
  end

  test 'simplified view' do
    nr_rows = 101
    nr_columns = 100
    csv_string1 = CSV.generate do |csv|
      (nr_rows + 1).times { |_i| csv << ['AAA'] * nr_columns }
    end

    csv_string2 = CSV.generate do |csv|
      (nr_rows + 1).times { |_i| csv << ['BBB'] * nr_columns }
    end

    diff_csv = DiffCsv.new(csv_string1.chomp, csv_string2.chomp)

    diff = html_output(
      [
        %(<th class="del"><strong>AAA</strong></th>)
      ] * nr_columns,
      [
        %(<td class="line-nr">#{(1..nr_rows).to_a.join "\n"}</td>) + %(<td class="del">#{(1..nr_rows).map { |_| 'AAA' }.join "\n"}</td>) * nr_columns
      ],
      [
        %(<th class="ins"><strong>BBB</strong></th>)
      ] * nr_columns,
      [
        %(<td class="line-nr">#{(1..nr_rows).to_a.join "\n"}</td>) + %(<td class="ins">#{(1..nr_rows).map { |_| 'BBB' }.join "\n"}</td>) * nr_columns
      ],
      true
    )
    should_match_html diff, diff_csv.split
  end
end
