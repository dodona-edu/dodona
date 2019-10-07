require 'test_helper'

class ApplicationHelperTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  setup do
    @exercise = create :exercise
    @series = create :series, exercises: [@exercise]
    @course = @series.course
  end

  test 'exercise_scoped_path' do
    assert_raises(Exception) do
      exercise_scoped_path
    end

    assert_equal exercise_path(I18n.locale, @exercise),
                 exercise_scoped_path(exercise: @exercise)

    assert_equal course_exercise_path(I18n.locale, @course, @exercise),
                 exercise_scoped_path(exercise: @exercise, course: @course)

    assert_equal course_series_exercise_path(I18n.locale, @course, @series, @exercise),
                 exercise_scoped_path(exercise: @exercise, course: @course, series: @series)
  end

  test 'edit_exercise_scoped_path' do
    assert_raises(Exception) do
      edit_exercise_scoped_path
    end

    assert_equal edit_exercise_path(I18n.locale, @exercise),
                 edit_exercise_scoped_path(exercise: @exercise)

    assert_equal edit_course_exercise_path(I18n.locale, @course, @exercise),
                 edit_exercise_scoped_path(exercise: @exercise, course: @course)

    assert_equal edit_course_series_exercise_path(I18n.locale, @course, @series, @exercise),
                 edit_exercise_scoped_path(exercise: @exercise, course: @course, series: @series)
  end

  test 'submissions_scoped_path' do
    assert_equal submissions_path(I18n.locale), submissions_scoped_path

    assert_equal exercise_submissions_path(I18n.locale, @exercise),
                 submissions_scoped_path(exercise: @exercise)

    assert_equal course_exercise_submissions_path(I18n.locale, @course, @exercise),
                 submissions_scoped_path(exercise: @exercise, course: @course)

    assert_equal course_series_exercise_submissions_path(I18n.locale, @course, @series, @exercise),
                 submissions_scoped_path(exercise: @exercise, course: @course, series: @series)
  end

  test 'sanitize helper should filter dangerous tags' do
    dirty_html = <<~HTML
      <script>alert(1)</script>
      <img src=x onerror=alert(1)>
      <p>Hello
    HTML
    clean_html = sanitize dirty_html
    assert_no_match(/<script>/, clean_html)
    assert_no_match(/onerror/, clean_html)
    assert_match(/<p>Hello/, clean_html)
  end

  test 'sanitize helper should allow custom tags' do
    dirty_html = <<~HTML
      <table style="background:black;">
        <thead>
          <td>Head</td>
        </thead>
        <tbody>
          <tr>
            <td>Data</td>
          </tr>
        </tbody>
      </table>
    HTML
    clean_html = sanitize dirty_html
    assert_equal dirty_html, clean_html
  end

  test 'sanitize helper should add \'rel="noopener noreferrer"\'' do
    dirty_html = <<~HTML
      <a target="_blank" href="cookies.com">
    HTML
    clean_html = sanitize dirty_html
    assert_match(/rel="noopener noreferrer"/, clean_html)
  end
end
