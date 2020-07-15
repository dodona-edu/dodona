require 'json'
require 'test_helper'
require 'timeout'

class SubmissionRunnerTest < ActiveSupport::TestCase
  setup do
    @repository = create :repository, :git_stubbed
    @judge = @repository.judge
    @course = create :course
    @user = create :user, courses: [@course]
    @series = create :series, course: @course
    @exercise = create :exercise,
                       :config_stubbed,
                       series: [@series],
                       repository: @repository
    @submission = create :submission,
                         user: @user,
                         course: @course,
                         exercise: @exercise
  end

  STRIKE_ERROR = 'DE HAVENVAKBOND STAAKT!!1!'.freeze

  def evaluate_with_stubbed_docker(obj = nil, **kwargs)
    obj ||= docker_mock(**kwargs)
    Docker::Container.stubs(:create).returns(obj)
    @submission.evaluate
  end

  def docker_mock(**params)
    default_params = {
      status_code: 0,
      output: {
        accepted: true,
        status: 'correct'
      }
    }

    params = default_params.merge(params)

    stdout = if params[:output].is_a?(Hash)
               params[:output].to_json
             else
               params[:output].to_s
             end

    obj = mock
    obj.stubs(:start)
    obj.stubs(:delete)
    obj.stubs(:attach).returns([[stdout], [params[:err]]])
    obj.stubs(:wait).returns('StatusCode' => params[:status_code])
    obj.stubs(:stats).returns(memory_stats: { max_usage: 100_000_000 })
    obj.stubs(:stop)
    obj
  end

  def assert_submission(status: nil, summary: nil, message_includes: nil, accepted: true)
    assert_not_nil @submission.result, 'There should always be a result'
    assert_equal status, @submission.status, 'Wrong submission status'
    summary ||= I18n.t("activerecord.attributes.submission.statuses.#{status}", locale: @submission.user.lang)
    assert_equal summary, @submission.summary, 'Wrong submission summary'
    if message_includes
      result = JSON.parse(@submission.result)
      messages = result['messages']
      message_contents = messages.map { |m| m['description'] }
      included = message_contents.any? { |m| m.include?(message_includes) }
      assert included,
             "Expected to find the text \n\"#{message_includes}\"\n" \
             "In one of the following messages of result:\n" \
             "#{message_contents}"
    end

    assert_equal accepted, @submission.accepted
  end

  test 'judge should receive merged config' do
    @exercise.update(programming_language: ProgrammingLanguage.create(name: 'whitespace'))
    @exercise.unstub(:config)
    # Stub global config
    File.stubs(:read)
        .with(Rails.root.join('app/runners/config.json'))
        .returns({ memory_limit: 100, time_limit: 42, network_enabled: false }.to_json)
    @submission.stubs(:code).returns(Random.new.alphanumeric(100))
    # Override something
    @exercise.stubs(:merged_config).returns({ evaluation: { network_enabled: true }.stringify_keys }.stringify_keys)
    mock = docker_mock
    mock.unstub(:attach)
    config = {}
    mock.expects(:attach).with do |args|
      config = JSON.parse(args[:stdin].read)
      true
    end
    evaluate_with_stubbed_docker mock
    assert_equal 100, config['memory_limit']
    assert_equal 42, config['time_limit']
    assert_equal true, config['network_enabled'] # overidden
    assert_equal @exercise.programming_language.name, config['programming_language']
    assert_equal @user.lang, config['natural_language']
    %w[resources source judge workdir].each do |key|
      path = config[key]
      assert_not_nil path
      assert path.starts_with?('/'), "Expected config[#{key}] to be an absolute path, but was '#{path}'"
    end
  end

  test 'submission evaluation should start docker container' do
    obj ||= docker_mock
    Docker::Container.expects(:create).once.returns(obj)
    @submission.evaluate
  end

  test 'correct submission should be accepted and correct' do
    summary = 'Wow. Such code. Many variables.'
    evaluate_with_stubbed_docker output: {
      accepted: true,
      status: 'correct',
      description: summary
    }
    assert_submission status: 'correct', summary: summary, accepted: true
  end

  test 'compilation error should not be accepted' do
    summary = 'Something something lifetimes.'
    evaluate_with_stubbed_docker output: {
      accepted: false,
      status: 'compilation error',
      description: summary
    }
    assert_submission status: 'compilation error', summary: summary, accepted: false
  end

  test 'runtime error should not be accepted' do
    summary = 'Could not compile exe.java'
    evaluate_with_stubbed_docker output: {
      accepted: false,
      status: 'runtime error',
      description: summary
    }
    assert_submission status: 'runtime error', summary: summary, accepted: false
  end

  test 'docker container should be deleted after use' do
    docker = docker_mock
    docker.expects(:delete)
    evaluate_with_stubbed_docker(docker)
  end

  test 'malformed json should result in internal error' do
    evaluate_with_stubbed_docker output: 'DIKKE TAARTEN!!1!'

    assert_submission status: 'internal error',
                      message_includes: 'Failed to parse the following JSON',
                      accepted: false
  end

  test 'no output should result in internal error' do
    evaluate_with_stubbed_docker output: nil
    assert_submission status: 'internal error',
                      message_includes: 'No judge output',
                      accepted: false
  end

  test 'broken output should result in internal error' do
    evaluate_with_stubbed_docker output: '{ status: "Aarhhg...'
    assert_submission status: 'internal error',
                      accepted: false
  end

  test 'too much output should result in output limit exceeded' do
    evaluate_with_stubbed_docker output: ('A' * 20 * 1024 * 1024)
    assert_submission status: 'output limit exceeded',
                      accepted: false
  end

  test 'non-zero status code should result in internal error' do
    evaluate_with_stubbed_docker status_code: 1,
                                 err: STRIKE_ERROR

    assert_submission status: 'internal error',
                      message_includes: STRIKE_ERROR,
                      accepted: false
  end

  test 'error in docker creation should result in internal error' do
    Docker::Container.stubs(:create).raises(STRIKE_ERROR)

    @submission.evaluate

    assert_submission status: 'internal error',
                      message_includes: "Error creating docker: #{STRIKE_ERROR}",
                      accepted: false
  end

  test 'random errors should be caught' do
    docker = docker_mock
    docker.stubs(:start).raises(STRIKE_ERROR)
    evaluate_with_stubbed_docker(docker)

    assert_submission status: 'internal error',
                      message_includes: STRIKE_ERROR,
                      accepted: false
  end

  test 'errors outside of docker startup should be sent to slack' do
    Delayed::Backend::ActiveRecord::Job.delete_all
    Rails.env.stubs(:"production?").returns(true)
    Submission.any_instance.stubs(:judge).raises(STRIKE_ERROR)
    ExceptionNotifier.stubs(:notify_exception).twice
    Docker::Container.stubs(:create).returns(docker_mock)
    @submission.evaluate_delayed
    Delayed::Worker.max_attempts = 1
    Delayed::Worker.new.work_off
  end

  class TimeoutDocker
    def initialize
      @running = Mutex.new
      @running_cond = ConditionVariable.new
    end

    def start; end

    def stop
      @running_cond.signal
    end

    def attach(_)
      @running.synchronize do
        @running_cond.wait(@running)
      end
      [[''], ['']]
    end

    def delete; end

    def wait(_)
      { 'StatusCode' => 143 }
    end
  end

  test 'docker killed because of time limit should result in timeout' do
    Docker::Container.stubs(:create).returns(TimeoutDocker.new)
    @submission.evaluate
    assert_equal 'time limit exceeded', @submission.status
  end

  class MemoryDocker
    def start; end

    def stop; end

    def attach(_)
      [[''], ['']]
    end

    def delete; end

    def wait(_)
      { 'StatusCode' => 143 }
    end
  end

  test 'docker killed but not because of time limit should result in memory limit' do
    Docker::Container.stubs(:create).returns(MemoryDocker.new)
    @submission.exercise.stubs(:merged_config).returns('evaluation' => { 'time_limit' => 1000 })
    @submission.evaluate
    assert_equal 'memory limit exceeded', @submission.status
  end
end
