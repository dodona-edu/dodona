require 'zip'

module ExportHelper
  class Zipper
    attr_reader :users, :item, :errors

    CONVERT_TO_BOOL = %w[indianio deadline all_students only_last_submission with_info all with_labels].freeze
    SUPPORTED_OPTIONS = %w[indianio deadline all_students group_by only_last_submission with_info all with_labels].freeze

    # Keywords used:
    # :item    : A User, Course or Series for which submissions will be exported
    # :list    : An Array of Courses, Series or Exercises depending on the item, a selection of items with submissions to export
    # :options : A Hash with multiple options as shown in SUPPORTED_OPTIONS, keys can be Strings or symbols
    #            When present, the respective Export#option? methods will be true
    #            group_by: String: user/student/personal to determine the filenames @see get_filename
    #            @see option? methods for details on what they do
    def initialize(**kwargs)
      @item = kwargs[:item]
      @options = get_options(kwargs[:options])
      @list = kwargs[:list]
      @users = kwargs[:users]
      case @item
      when Series
        @list = @item.exercises if all?
        @users_labels = @item.course
                             .course_memberships
                             .includes(:course_labels, :user)
                             .map { |m| [m.user, m.course_labels] }
                             .to_h
        @users = @users_labels.keys if users.nil?
      when Course
        @list = @item.series if all?
        @users_labels = @item.course_memberships
                             .includes(:course_labels, :user)
                             .map { |m| [m.user, m.course_labels] }
                             .to_h
        @users = @users_labels.keys if users.nil?
        initialize_series_per_exercise # depends on @list
      when User
        @list = @item.courses if all?
        @users = [@item]
        initialize_series_per_exercise
      end
      @seen = {
        courses: Hash.new(0),
        exercises: Hash.new(0),
        series: Hash.new(0),
        users: Hash.new(0)
      }
      @names = {
        courses: {},
        exercises: {},
        series: {},
        users: {}
      }
    end

    def labels?
      @options[:with_labels].present?
    end

    # Exporting a zip for Indianio: make sure to return specific output for this request
    def indianio?
      @options[:indianio].present?
    end

    # Whether to include all submissions or just the last one per exercise
    def only_last_submission?
      @options[:only_last_submission].present?
    end

    #  Only export submissions created before the deadline of the series they are in
    def deadline?
      @options[:deadline].present?
    end

    #  Add a CSV to the zip with information about the downloaded files
    def with_info?
      @options[:with_info].present?
    end

    # includes all students in the zip by adding an empty text file for exercises they did not finish
    def all_students?
      @options[:all_students].present?
    end

    # Export all submissions, even those not part of a series/course
    def all?
      @options[:all].present?
    end

    def zip_filename
      return "#{@item.name.parameterize}-#{@users.first.full_name.parameterize}.zip" if indianio?

      @item.is_a?(User) ? "#{@item.full_name.parameterize}.zip" : "#{@item.name.parameterize}.zip"
    end

    def ex_fn(ex)
      return @names[:exercises][ex.id] if @names[:exercises][ex.id].present?

      base = ex.name.parameterize
      name = base
      name += "-#{@seen[:exercises][base]}" if @seen[:exercises][base] > 0
      @seen[:exercises][base] += 1
      @names[:exercises][ex.id] = name
      name
    end

    def user_fn(u)
      return @names[:users][u.id] if @names[:users][u.id].present?

      base = u.full_name
      name = base
      name += "-#{@seen[:users][base]}" if @seen[:users][base] > 0
      @seen[:users][base] += 1
      @names[:users][u.id] = name
      name
    end

    def series_fn(s)
      return @names[:series][s.id] if @names[:series][s.id].present?

      base = s.name.parameterize
      name = base
      name += "-#{@seen[:series][base]}" if @seen[:series][base] > 0
      @seen[:series][base] += 1
      @names[:series][s.id] = name
      name
    end

    def course_fn(c)
      return @names[:courses][c.id] if @names[:courses][c.id].present?

      base = c.name.parameterize
      name = base
      name += "-#{@seen[:courses][base]}" if @seen[:courses][base] > 0
      @seen[:courses][base] += 1
      @names[:courses][c.id] = name
      name
    end

    # Constructs a filename for the given combination of user, exercise and possible submission
    # If group_by == user: the filename will end with username/exercise_name
    # If group_by == exercise: the filename will end with exercise_name/username
    # If group_by == personal, the username will be omitted from the filename
    # If the submission is not nil and multiple submissions can be present in the zip, the submission id will be included in the filename
    # If a course is being exported, the names of the series will be present in the filenames
    # If the submissions of a user are being exported, the course name will also be present if it exists for the submission
    def get_filename(user, exercise, submission = nil)
      return exercise.file_name if indianio?

      ex_and_series_fn = ex_fn(exercise)
      unless @item.is_a?(Series)
        series = @series_per_exercise[exercise.id]
        if series.nil?
          ex_and_series_fn = "#{I18n.t('export.download_submissions.no_series')}/#{ex_and_series_fn}"
        else
          ex_and_series_fn = "#{series_fn(series)}/#{ex_and_series_fn}"
          ex_and_series_fn = "#{course_fn(series.course)}/#{ex_and_series_fn}" if @item.is_a?(User)
        end
      end

      fn = case @options[:group_by]
           when 'user'
             "#{user_fn(user)}/#{ex_and_series_fn}"
           when 'personal'
             ex_and_series_fn
           when nil, 'exercise'
             "#{ex_and_series_fn}/#{user_fn(user)}"
           else
             raise ArgumentError, "Unknown grouping option supplied: #{@options[:group_by]}"
           end
      fn += "/#{submission.id}" unless submission.nil? || only_last_submission? # Do not generate folders unless multiple submissions must be sent
      "#{fn}.#{exercise.file_extension}"
    end

    def generate_zip_data(users, exercises, submissions)
      exercises_per_user = Hash.new { |hash, user| hash[user] = Set.new }
      stringio = Zip::OutputStream.write_buffer do |zio|
        info = CSV.generate(force_quotes: true) do |csv|
          csv << if indianio?
                   %w[filename status submission_id name_en name_nl exercise_id]
                 else
                   headers = %w[filename full_name id status submission_id name_en name_nl exercise_id created_at]
                   headers << 'labels' if labels?
                   headers
                 end
          submissions.each do |submission|
            exercises_per_user[submission.user.id].add(submission.activity.id)
            filename = get_filename submission.user, submission.activity, submission
            write_submission(zio, submission, filename)
            csv_submission(csv, submission.user, submission.activity, submission, filename)
          end
          if all_students? # Loop over all user/exercise-combinations to write an empty file to include them in the zip
            users.each do |user|
              exercises.each do |exercise|
                if exercises_per_user[user.id].include? exercise.id
                  next # this combination has been found in the earlier submissions
                end

                filename = get_filename user, exercise
                write_submission(zio, nil, filename)
                csv_submission(csv, user, exercise, nil, filename)
              end
            end
          end
        end
        if with_info?
          zio.put_next_entry('info.csv')
          zio.write info
        end
      end
      stringio.rewind
      stringio.sysread
    end

    def write_submission(zio, submission, filename)
      zio.put_next_entry(filename)
      zio.write(submission&.code)
    end

    def csv_submission(csv, user, exercise, submission, filename)
      csv << if indianio?
               [filename, submission&.status, submission&.id, exercise.name_en, exercise.name_nl, exercise.id]
             else
               row = [filename, user.full_name, user.id, submission&.status, submission&.id, exercise.name_en, exercise.name_nl, exercise.id, submission&.created_at]
               row << @users_labels[user].map(&:name).join(';') if labels?
               row
             end
    end

    def bundle
      case @item
      when Series
        @options[:deadline] = @item.deadline || Time.current.tomorrow if deadline? # Prevent nil-deadline if series has no deadline
        submissions = get_submissions_for_series(@list, @users)
        exercises = @list
      when Course
        submissions = get_submissions_for_course(@list, @users)
        exercises = @list.map(&:exercises).flatten
      else # is User
        submissions = get_submissions_for_user(@list)
        exercises = submissions.map(&:activity).uniq
      end

      { data: generate_zip_data(@users, exercises, submissions), filename: zip_filename }
    end

    def get_submissions_for_series(selected_exercises, users)
      submissions = Submission.all.where(user_id: users.map(&:id), activity_id: selected_exercises.map(&:id)).includes(:user, :activity)
      submissions = submissions.before_deadline(@options[:deadline]) if deadline?
      submissions = submissions.group(:user_id, :activity_id).most_recent if only_last_submission?
      submissions.sort_by { |s| [selected_exercises.map(&:id).index(s.activity_id), users.map(&:id).index(s.user_id), s.id] }
    end

    def get_submissions_for_course(selected_series, users)
      selected_series.map do |series|
        @options[:deadline] = series.deadline || Time.current.tomorrow if deadline? # Prevent nil-deadline if series has no deadline
        get_submissions_for_series(series.exercises, users)
      end.flatten
    end

    def get_submissions_for_user(selected_courses)
      return Submission.of_user(@item).includes(:user, :activity) if all? # allow submissions without a course

      selected_courses.map { |course| get_submissions_for_course(course.series, @users) }.flatten
    end

    private

    def initialize_series_per_exercise
      @series_per_exercise = {}
      return if @item.nil? || @list.nil?

      all_series = @item.is_a?(Course) ? @list : @list.map(&:series).flatten
      all_series.each do |series|
        series.exercises.each { |ex| @series_per_exercise[ex.id] = series }
      end
    end

    def get_options(params)
      return {} if params.nil?

      options = params.select { |key, _| SUPPORTED_OPTIONS.include? key.to_s }
      CONVERT_TO_BOOL.each { |key| options[key.to_sym] = ActiveModel::Type::Boolean.new.cast(options[key.to_sym].to_s.downcase) }
      options
    end
  end
end
