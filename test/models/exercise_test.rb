# == Schema Information
#
# Table name: exercises
#
#  id                   :integer          not null, primary key
#  name_nl              :string(255)
#  name_en              :string(255)
#  visibility           :integer          default("open")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  path                 :string(255)
#  description_format   :string(255)
#  programming_language :string(255)
#  repository_id        :integer
#  judge_id             :integer
#  status               :integer          default("ok")
#

require 'test_helper'

class ExerciseTest < ActiveSupport::TestCase
  test 'factory' do
    create :exercise
  end
end

class ExerciseRemoteTest < ActiveSupport::TestCase
  setup do
    @remote = local_remote('exercises/echo')
    @repository = create :repository, remote: @remote.path
    @repository.process_exercises
    @exercise = @repository.exercises.first

    # allow pushing
    Rails.env.stubs(:production?).returns(true)
  end

  teardown do
    @remote.remove
    @repository.git_repository.remove
  end

  def config
    JSON.parse(File.read(@exercise.config_file))
  end

  test 'should update visibility in config file' do
    @exercise.update visibility: 'hidden'
    assert_equal 'hidden', config['visibility']
  end

  test 'should update name_nl in config file' do
    @exercise.update name_nl: 'Echo'
    assert_equal 'Echo', config['description']['names']['nl']
  end

  test 'should update name_en in config file' do
    @exercise.update name_en: 'Echo'
    assert_equal 'Echo', config['description']['names']['en']
  end

  test 'should push to remote' do
    assert_difference('@remote.commit_count', 1) do
      @exercise.update visibility: 'hidden'
    end
  end

  test 'should push changes' do
    @exercise.update visibility: 'hidden'
    config = JSON.parse(
      File.read(File.join(@remote.path, @exercise.path, 'config.json'))
    )
    assert_equal 'hidden', config['visibility']
  end
end

# multiple layers of configurations; tests merging.
class LasagneTest < ActiveSupport::TestCase
  setup do
    @judge = create :judge, :git_stubbed, name: 'Iona Nikitchenko'
    @remote = local_remote('exercises/lasagna')
    @repository = create :repository, remote: @remote.path
    @repository.process_exercises
    @exercise = @repository.exercises.first
  end

  teardown do
    @remote.remove
    @repository.git_repository.remove
  end

  # set top level, overridden by exercise
  test 'should set judge' do
    assert_equal @judge, @exercise.judge
  end

  # set at top level, overridden by series, overridden by exercise
  test 'should set programming language' do
    assert_equal 'python', @exercise.programming_language
  end

  # set at top level, overridden by series
  test 'should set visibility' do
    assert_equal 'open', @exercise.visibility
  end
end
