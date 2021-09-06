# == Schema Information
#
# Table name: score_items
#
#  id                     :bigint           not null, primary key
#  evaluation_exercise_id :bigint           not null
#  maximum                :decimal(5, 2)    not null
#  name                   :string(255)      not null
#  visible                :boolean          default(TRUE), not null
#  description            :text(65535)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
require 'test_helper'

class ScoreItemTest < ActiveSupport::TestCase
  setup do
    series = create :series, exercise_count: 2
    users = [users(:student), users(:staff)]
    users.each do |u|
      series.course.enrolled_members << u
      create :submission, user: u, exercise: series.exercises.first, course: series.course, created_at: Time.current - 1.hour
    end
    @evaluation = create :evaluation, series: series, users: users, exercises: series.exercises
  end

  test 'completed feedbacks are uncompleted' do
    @evaluation.feedbacks.each { |f| f.update!(completed: true) }
    eval_exercise = @evaluation.evaluation_exercises.find { |e| e.exercise.submissions.count == 2 }
    create :score_item, evaluation_exercise: eval_exercise

    eval_exercise.feedbacks.each do |f|
      assert_not f.completed?
    end
  end

  test 'bank feedbacks are set to zero' do
    eval_exercise = @evaluation.evaluation_exercises.find { |e| e.exercise.submissions.count == 0 }
    create :score_item, evaluation_exercise: eval_exercise

    eval_exercise.feedbacks.each do |f|
      assert f.completed?
      assert f.scores.count == 1
    end
  end

  test 'updating maximum scores uncompletes feedbacks' do
    eval_exercise = @evaluation.evaluation_exercises.find { |e| e.exercise.submissions.count == 2 }
    score_item = create :score_item, evaluation_exercise: eval_exercise
    @evaluation.feedbacks.each { |f| f.update(completed: true) }

    score_item.update(maximum: '20.0')

    eval_exercise.feedbacks.each do |f|
      assert_not f.completed?
    end
  end

  test 'updating other attributes does not uncomplete feedbacks' do
    eval_exercise = @evaluation.evaluation_exercises.find { |e| e.exercise.submissions.count == 2 }
    score_item = create :score_item, evaluation_exercise: eval_exercise
    @evaluation.feedbacks.each { |f| f.update(completed: true) }

    score_item.update(description: 'Hallo')

    eval_exercise.feedbacks.each do |f|
      assert f.completed?
    end
  end

  test 'updating maximum scores does uncomplete blank feedbacks' do
    eval_exercise = @evaluation.evaluation_exercises.find { |e| e.exercise.submissions.count == 0 }
    score_item = create :score_item, evaluation_exercise: eval_exercise
    @evaluation.feedbacks.each { |f| f.update(completed: true) }

    score_item.update(maximum: '20.0')

    eval_exercise.feedbacks.each do |f|
      assert f.completed?
    end
  end
end

class SimpleScoreItemTest < ActiveSupport::TestCase
  test 'maximum must be positive' do
    assert_raises ActiveRecord::RecordInvalid do
      create :score_item, maximum: '-10.0'
    end
  end
end
