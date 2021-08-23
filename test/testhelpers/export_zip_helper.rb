module SeriesZipHelper
  def assert_zip(zip_data, options = {})
    zipio = StringIO.new(zip_data)
    with_info = options[:with_info]
    Zip::File.open_buffer(zipio) do |zip|
      has_info = false
      other_entries = 0
      zip.each do |entry|
        if entry.name == 'info.csv'
          has_info = true
          check_csv entry if with_info
        else
          check_entry(entry, options)
          other_entries += 1
        end
      end
      unless with_info.nil?
        if with_info
          assert has_info, 'zip file should contain info.csv but did not'
        else
          assert_not has_info, 'zip file should not contain info.csv but did'
        end
      end
      assert_equal options[:solution_count], other_entries, 'unexpected submission count in csv' if options[:solution_count].present?
    end
  end

  def check_csv(entry)
    csv = entry.get_input_stream.read
    header = csv.split("\n").first
    %w[filename id username last_name first_name full_name email status submission_id exercise_id name_nl name_en].each do |h|
      assert header.include?("\"#{h}\""), "info.csv header did not include #{h}"
    end
  end

  def check_entry(entry, options)
    data = options[:data]
    utf8_name = entry.name.force_encoding('utf-8')
    case options[:group_by]
    when 'user'
      assert data[:users].any? { |u| utf8_name.start_with? u.full_name }, "The submissions are not grouped by students but should be, example: #{utf8_name}."
    when 'exercise', nil
      assert data[:exercises].any? { |ex| utf8_name.start_with? ex.name.parameterize }, "The submissions are not grouped by exercise but should be, example: #{utf8_name}."
    when 'series'
      assert data[:course].series.any? { |series| utf8_name.start_with? series.name.parameterize }, "The submissions are not grouped by series but should be, example: #{utf8_name}."
    when 'course'
      assert data[:user].courses.any? { |course| utf8_name.start_with? course.name.parameterize }, "The submissions are not grouped by course but should be, example: #{utf8_name}."
    else
      raise ArgumentError, 'Unknown group_by option supplied'
    end
  end
end
