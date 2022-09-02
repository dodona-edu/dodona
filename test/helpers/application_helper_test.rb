require 'test_helper'

class ApplicationHelperTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  include ApplicationHelper

  setup do
    @activity = create :exercise
    @content_page = create :content_page
    @series = create :series, exercises: [@activity]
    @course = @series.course
  end

  test 'activity_scoped_path' do
    assert_raises(Exception) do
      activity_scoped_path
    end

    assert_equal activity_path(I18n.locale, @activity),
                 activity_scoped_path(activity: @activity)

    assert_equal course_activity_path(I18n.locale, @course, @activity),
                 activity_scoped_path(activity: @activity, course: @course)

    assert_equal course_series_activity_path(I18n.locale, @course, @series, @activity),
                 activity_scoped_path(activity: @activity, course: @course, series: @series)
  end

  test 'edit_activity_scoped_path' do
    assert_raises(Exception) do
      edit_activity_scoped_path
    end

    assert_equal edit_activity_path(I18n.locale, @activity),
                 edit_activity_scoped_path(activity: @activity)

    assert_equal edit_course_activity_path(I18n.locale, @course, @activity),
                 edit_activity_scoped_path(activity: @activity, course: @course)

    assert_equal edit_course_series_activity_path(I18n.locale, @course, @series, @activity),
                 edit_activity_scoped_path(activity: @activity, course: @course, series: @series)
  end

  test 'submissions_scoped_path' do
    assert_equal submissions_path(I18n.locale), submissions_scoped_path

    assert_equal activity_submissions_path(I18n.locale, @activity),
                 submissions_scoped_path(exercise: @activity)

    assert_equal course_activity_submissions_path(I18n.locale, @course, @activity),
                 submissions_scoped_path(exercise: @activity, course: @course)

    assert_equal course_series_activity_submissions_path(I18n.locale, @course, @series, @activity),
                 submissions_scoped_path(exercise: @activity, course: @course, series: @series)
  end

  test 'activity_read_states_scoped_path' do
    assert_equal activity_read_states_path(I18n.locale), activity_read_states_scoped_path

    assert_equal activity_activity_read_states_path(I18n.locale, @content_page),
                 activity_read_states_scoped_path(content_page: @content_page)

    assert_equal course_activity_activity_read_states_path(I18n.locale, @course, @content_page),
                 activity_read_states_scoped_path(content_page: @content_page, course: @course)

    assert_equal course_series_activity_activity_read_states_path(I18n.locale, @course, @series, @content_page),
                 activity_read_states_scoped_path(content_page: @content_page, course: @course, series: @series)
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

  test 'language tags are used correctly' do
    def current_user
      create :user
    end
    self.locale = 'nl-BE'
    assert_equal :nl, I18n.locale

    self.locale = 'nl'
    assert_equal :nl, I18n.locale

    self.locale = 'en'
    assert_equal :en, I18n.locale

    self.locale = 'en-UK'
    assert_equal :en, I18n.locale

    self.locale = :en
    assert_equal :en, I18n.locale

    self.locale = 'garbage-stuff-does-not_exist'
    assert_equal I18n.default_locale, I18n.locale
  end
end
