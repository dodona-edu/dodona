module SeriesZipHelper
  def assert_zip(zip_data, entry_count: nil, with_info: nil)
    zipio = StringIO.new(zip_data)
    Zip::File.open_buffer(zipio) do |zip|
      entries = 0
      has_info = false
      zip.each do |entry|
        if entry.name == 'info.csv'
          has_info = true
          check_csv entry if with_info
        end
        entries += 1
      end
      unless with_info.nil?
        if with_info
          assert has_info, 'zip file should contain info.csv but did not'
        else
          assert_not has_info, 'zip file should not contain info.csv but did'
        end
      end
      assert_equal entry_count, entries if entry_count
    end
  end

  def check_csv(entry)
    csv = entry.get_input_stream.read
    header = csv.split("\n").first
    %w[filename status submission_id exercise_id name_nl name_en].each do |h|
      assert header.include?("\"#{h}\""), "info.csv header did not include #{h}"
    end
  end
end
