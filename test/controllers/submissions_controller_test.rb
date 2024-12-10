require 'test_helper'

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  extend CRUDTest
  include EvaluationHelper

  crud_helpers Submission, attrs: %i[code exercise_id]

  setup do
    stub_all_activities!
    @instance = create :correct_submission
    @zeus = users(:zeus)
    sign_in @zeus
  end

  test_crud_actions only: %i[index show create], except: %i[create_redirect]

  test 'should fetch last correct submissions for exercise' do
    users = create_list :user, 2
    c = create :course, series_count: 1, activities_per_series: 1
    e = c.series.first.exercises.first

    submissions = users.map { |u| create :correct_submission, user: u, exercise: e, course: c }
    users.each { |u| create :wrong_submission, user: u, exercise: e, course: c }

    # create a correct submission with another exercise, to check if
    # most_recent works
    create :correct_submission, user: users.first

    get course_activity_submissions_url c, e, most_recent_per_user: true, status: :correct, format: :json

    results = response.parsed_body
    result_ids = results.pluck('id')

    assert_equal submissions.count, result_ids.count
    submissions.each do |sub|
      assert_includes result_ids, sub.id
    end
  end

  test 'should be able to search by exercise name' do
    u = create :user
    sign_in u
    e1 = create :exercise, name_en: 'abcd'
    e2 = create :exercise, name_en: 'efgh'
    create :submission, exercise: e1, user: u
    create :submission, exercise: e2, user: u

    get submissions_url, params: { filter: 'abcd', format: :json }

    assert_equal 1, response.parsed_body.count
  end

  test 'should be able to search by user name' do
    u1 = create :user, last_name: 'abcd'
    u2 = create :user, last_name: 'efgh'
    create :submission, user: u1
    create :submission, user: u2

    get submissions_url, params: { filter: 'abcd', format: :json }

    assert_equal 1, response.parsed_body.count
  end

  test 'should be able to search by status' do
    u = create :user
    sign_in u
    create :submission, status: :correct, user: u
    create :submission, status: :wrong, user: u

    get submissions_url, params: { status: 'correct', format: :json }

    assert_equal 1, response.parsed_body.count
  end

  test 'should be able to search by course label' do
    u1 = users(:student)
    u2 = users(:staff)
    course = courses(:course1)
    cm = CourseMembership.create(user: u1, course: course, status: :student)
    CourseMembership.create(user: u2, course: course, status: :student)
    CourseLabel.create(name: 'test', course_memberships: [cm], course: course)
    create :submission, status: :correct, user: u1, course: course
    create :submission, status: :wrong, user: u2, course: course
    get course_submissions_url course, params: { course_labels: ['test'], format: :json }

    assert_equal 1, response.parsed_body.count
  end

  test 'normal user should not be able to search by course label' do
    u1 = users(:student)
    u2 = users(:staff)
    sign_in u2
    course = courses(:course1)
    cm = CourseMembership.create(user: u1, course: course, status: :student)
    CourseMembership.create(user: u2, course: course, status: :student)
    CourseLabel.create(name: 'test', course_memberships: [cm], course: course)
    create :submission, status: :correct, user: u1, course: course
    create :submission, status: :wrong, user: u2, course: course

    get course_submissions_url course, params: { course_labels: ['test'], format: :json }

    assert_equal 1, response.parsed_body.count
  end

  test 'submission http caching works' do
    get submissions_path

    assert_response :ok
    assert_not_empty @response.headers['ETag']
    assert_not_empty @response.headers['Last-Modified']
    get submissions_path, headers: {
      'If-None-Match' => @response.headers['ETag'],
      'If-Modified-Since' => @response.headers['Last-Modified']
    }

    assert_response :not_modified
  end

  test 'should add submissions to delayed_job queue' do
    submission = nil
    assert_jobs_enqueued(1) do
      submission = create_request_expect
    end
    assert_predicate submission, :queued?
  end

  test 'create submission should respond with ok' do
    create_request_expect

    assert_response :success
  end

  test 'should not create submission for content page' do
    attrs = generate_attr_hash
    attrs[:exercise_id] = create(:content_page).id
    create_request(attr_hash: attrs)

    assert_response :unprocessable_entity
  end

  test 'create submission should respond unprocessable_entity without an exercise' do
    attrs = generate_attr_hash
    attrs.delete(:exercise_id)
    create_request(attr_hash: attrs)

    assert_response :unprocessable_entity
  end

  test 'create submission should respond bad_request without a hash' do
    post submissions_url

    assert_response :bad_request
  end

  test 'create submission within course' do
    attrs = generate_attr_hash
    course = courses(:course1)
    course.subscribed_members << @zeus
    course.series << create(:series)
    course.series.first.exercises << Exercise.find(attrs[:exercise_id])
    attrs[:course_id] = course.id

    submission = create_request_expect attr_hash: attrs

    assert_not_nil submission.course, 'Course was not properly set'
    assert_equal course.id, submission.course.id
  end

  test 'unregistered user submitting to private exercise in moderated course should fail' do
    attrs = generate_attr_hash
    course = create :course, moderated: true
    exercise = Exercise.find(attrs[:exercise_id])
    exercise.update(access: :private)
    course.series << create(:series)
    course.series.first.exercises << exercise
    attrs[:course_id] = course.id
    user = create :user
    sign_in user

    create_request attr_hash: attrs

    assert_response :unprocessable_entity
  end

  test 'unregistered user submitting to exercise in hidden series should fail' do
    attrs = generate_attr_hash
    course = courses(:course1)
    exercise = Exercise.find(attrs[:exercise_id])
    course.series << create(:series, visibility: :hidden)
    course.series.first.exercises << exercise
    attrs[:course_id] = course.id
    user = create :user
    sign_in user

    create_request attr_hash: attrs

    assert_response :unprocessable_entity
  end

  test 'should get submission edit page' do
    get edit_submission_path(@instance)

    assert_redirected_to activity_url(
      @instance.exercise,
      anchor: 'submission-card',
      edit_submission: @instance
    )
  end

  test 'should download submission code' do
    get download_submission_path(@instance)

    assert_response :success
  end

  test 'should evaluate submission' do
    assert_difference('Delayed::Job.count', +1) do
      get evaluate_submission_path(@instance)

      assert_redirected_to @instance
    end
  end

  test 'submission media should redirect to exercise media' do
    get media_submission_path(@instance, 'dank_meme.jpg')

    assert_redirected_to media_activity_path(@instance.exercise, 'dank_meme.jpg')
  end

  test 'submission media should redirect to exercise media and keep token' do
    get media_submission_path(@instance, 'dank_meme.jpg', token: @instance.exercise.access_token)

    assert_redirected_to media_activity_path(@instance.exercise, 'dank_meme.jpg', token: @instance.exercise.access_token)
  end

  def rejudge_submissions(**params)
    post mass_rejudge_submissions_path, params: params

    assert_response :success
  end

  test 'should enqeueue submissions delayed ' do
    create :series, :with_submissions

    # in test env, default and export queues are evaluated inline
    with_delayed_jobs do
      # should only enqueue a single job which will then enqueue all other jobs
      assert_jobs_enqueued(1) do
        rejudge_submissions
      end
    end
  end

  test 'should rejudge all submissions' do
    create :series, :with_submissions
    assert_jobs_enqueued(Submission.count) do
      rejudge_submissions
    end
  end

  test 'should rejudge user submissions' do
    series = create :series, :with_submissions
    user = User.in_course(series.course).sample
    assert_jobs_enqueued(user.submissions.count) do
      rejudge_submissions user_id: user.id
    end
  end

  test 'should rejudge course submissions' do
    series = create :series, :with_submissions
    series.course.subscribed_members << @zeus
    assert_jobs_enqueued(Submission.in_course(series.course).count) do
      rejudge_submissions course_id: series.course.id
    end
  end

  test 'should rejudge series submissions' do
    series = create :series, :with_submissions
    series.course.subscribed_members << @zeus
    assert_jobs_enqueued(Submission.in_series(series).count) do
      rejudge_submissions series_id: series.id
    end
  end

  test 'should rejudge exercise submissions' do
    series = create :series, :with_submissions
    exercise = series.exercises.sample
    assert_jobs_enqueued(exercise.submissions.count) do
      rejudge_submissions activity_id: exercise.id
    end
  end

  def expected_score_string(*args)
    if args.length == 1
      "#{format_score(args[0].score)} / #{format_score(args[0].score_item.maximum)}"
    else
      "#{format_score(args[0])} / #{format_score(args[1])}"
    end
  end

  test 'should only show allowed grades for students' do
    evaluation = create :evaluation, :released, :with_submissions
    evaluation_exercise = evaluation.evaluation_exercises.first
    visible_score_item = create :score_item, evaluation_exercise: evaluation_exercise
    hidden_score_item = create :score_item, evaluation_exercise: evaluation_exercise, visible: false
    feedback = evaluation.feedbacks.first
    submission = feedback.submission
    s1 = create :score, feedback: feedback, score_item: visible_score_item, score: BigDecimal('5.00')
    s2 = create :score, feedback: feedback, score_item: hidden_score_item, score: BigDecimal('7.00')

    sign_in submission.user

    get submission_url(id: submission.id)

    assert_match visible_score_item.description, response.body
    assert_no_match hidden_score_item.description, response.body
    assert_match expected_score_string(s1), response.body
    assert_no_match expected_score_string(s2), response.body
    assert_match expected_score_string(feedback.score, feedback.maximum_score), response.body

    # Hidden total is not shown
    evaluation_exercise.update!(visible_score: false)
    get submission_url(id: submission.id)

    assert_match visible_score_item.description, response.body
    assert_no_match hidden_score_item.description, response.body
    assert_match expected_score_string(s1), response.body
    assert_no_match expected_score_string(s2), response.body
    assert_no_match expected_score_string(feedback.score, feedback.maximum_score), response.body

    # The evaluation is no longer released
    evaluation.update!(released: false)
    get submission_url(id: submission.id)

    assert_no_match visible_score_item.description, response.body
    assert_no_match hidden_score_item.description, response.body
    assert_no_match expected_score_string(s1), response.body
    assert_no_match expected_score_string(s2), response.body
    assert_no_match expected_score_string(feedback.score, feedback.maximum_score), response.body
  end

  test 'shows all grades for zeus & staff members' do
    evaluation = create :evaluation, :released, :with_submissions
    evaluation_exercise = evaluation.evaluation_exercises.first
    visible_score_item = create :score_item, evaluation_exercise: evaluation_exercise
    hidden_score_item = create :score_item, evaluation_exercise: evaluation_exercise, visible: false
    feedback = evaluation.feedbacks.first
    submission = feedback.submission
    s1 = create :score, feedback: feedback, score_item: visible_score_item, score: BigDecimal('5.00')
    s2 = create :score, feedback: feedback, score_item: hidden_score_item, score: BigDecimal('7.00')

    staff = create :staff
    staff.administrating_courses << evaluation.series.course
    [@zeus, staff].each do |user|
      sign_in user

      get submission_url(id: submission.id)

      assert_match visible_score_item.description, response.body
      assert_match hidden_score_item.description, response.body
      assert_match expected_score_string(s1), response.body
      assert_match expected_score_string(s2), response.body
      assert_match expected_score_string(feedback.score, feedback.maximum_score), response.body

      # Hidden total is not shown
      evaluation_exercise.update!(visible_score: false)
      get submission_url(id: submission.id)

      assert_match visible_score_item.description, response.body
      assert_match hidden_score_item.description, response.body
      assert_match expected_score_string(s1), response.body
      assert_match expected_score_string(s2), response.body
      assert_match expected_score_string(feedback.score, feedback.maximum_score), response.body

      # The evaluation is no longer released
      evaluation.update!(released: false)
      get submission_url(id: submission.id)

      assert_match visible_score_item.description, response.body
      assert_match hidden_score_item.description, response.body
      assert_match expected_score_string(s1), response.body
      assert_match expected_score_string(s2), response.body
      assert_match expected_score_string(feedback.score, feedback.maximum_score), response.body
    end
  end

  test 'should be able to order most recent submissions by user' do
    u = create :user, first_name: 'abcd'
    u2 = create :user, first_name: 'efgh'
    course = create :course, series_count: 1, activities_per_series: 1
    e = course.series.first.exercises.first
    create :submission, exercise: e, user: u, course: course, created_at: 2.minutes.ago, status: :correct
    least_recent = create :submission, exercise: e, user: u2, course: course, created_at: 1.minute.ago, status: :wrong
    most_recent = create :submission, exercise: e, user: u, course: course, status: :running

    get course_series_activity_submissions_path(course, course.series.first, e), params: { most_recent_per_user: true, format: :json }

    assert_equal 2, response.parsed_body.count
    assert_equal most_recent.id, response.parsed_body.first['id']
    assert_equal least_recent.id, response.parsed_body.second['id']

    get course_series_activity_submissions_path(course, course.series.first, e), params: { most_recent_per_user: true, order_by: { column: 'created_at', direction: 'ASC' }, format: :json }

    assert_equal 2, response.parsed_body.count
    assert_equal least_recent.id, response.parsed_body.first['id']
    assert_equal most_recent.id, response.parsed_body.second['id']

    get course_series_activity_submissions_path(course, course.series.first, e), params: { most_recent_per_user: true, order_by: { column: 'created_at', direction: 'DESC' }, format: :json }

    assert_equal 2, response.parsed_body.count
    assert_equal most_recent.id, response.parsed_body.first['id']
    assert_equal least_recent.id, response.parsed_body.second['id']

    get course_series_activity_submissions_path(course, course.series.first, e), params: { most_recent_per_user: true, order_by: { column: 'user', direction: 'DESC' }, format: :json }

    assert_equal 2, response.parsed_body.count
    assert_equal least_recent.id, response.parsed_body.first['id']
    assert_equal most_recent.id, response.parsed_body.second['id']

    get course_series_activity_submissions_path(course, course.series.first, e), params: { most_recent_per_user: true, order_by: { column: 'user', direction: 'ASC' }, format: :json }

    assert_equal 2, response.parsed_body.count
    assert_equal most_recent.id, response.parsed_body.first['id']
    assert_equal least_recent.id, response.parsed_body.second['id']

    get course_series_activity_submissions_path(course, course.series.first, e), params: { most_recent_per_user: true, order_by: { column: 'status', direction: 'DESC' }, format: :json }

    assert_equal 2, response.parsed_body.count
    assert_equal most_recent.id, response.parsed_body.first['id']
    assert_equal least_recent.id, response.parsed_body.second['id']

    get course_series_activity_submissions_path(course, course.series.first, e), params: { most_recent_per_user: true, order_by: { column: 'status', direction: 'ASC' }, format: :json }

    assert_equal 2, response.parsed_body.count
    assert_equal least_recent.id, response.parsed_body.first['id']
    assert_equal most_recent.id, response.parsed_body.second['id']
  end

  test 'rendering pythia submission should not crash' do
    stub_git(Judge.any_instance)
    judge = create :judge, name: 'pythia', renderer: PythiaRenderer
    exercise = create :exercise, judge: judge
    submission = create :submission, :wrong, exercise: exercise
    submission.result = '{
      "accepted": false,
      "status": "wrong",
      "description": "Onverwachte uitvoer",
      "annotations": [],
      "groups": [
        {
          "description": "maximum",
          "badgeCount": 6,
          "groups": []
        }
      ],
      "messages": []
    }'
    get submission_path(submission)

    assert_response :ok
  end

  test 'should be able to use legacy paths containing `exercise`' do
    course = create :course, series_count: 1, activities_per_series: 1
    get course_series_exercise_submissions_path(course, course.series.first, course.series.first.exercises.first)

    assert_response :ok
  end

  test 'Should be able to render submissions with csv`s with empty rows' do
    submission = create :wrong_submission, code: 'SELECT substr(name,4) FROM artist;',
                                           result: "{\"accepted\":false,\"status\":\"wrong\",\"description\":\"Test gefaald\",\"groups\":[{\"description\":\"Validatie\",\"badgeCount\":3,\"groups\":[{\"accepted\":false,\"groups\":[{\"description\":\"Resultaten vergelijken\",\"accepted\":false,\"tests\":[{\"expected\":\"name\\n$pyda\\n1000 Ohm\\n1001 Night Society\\n7 Days In Egypt\\nAC-DC\\nAbdullah Chhadeh\\nAboutou Roots\\nAdmiral Freebee\\nAfricanism All Stars\\nAfrikan Boy\\nAfro Celt Sound System\\nAfter Forever\\nAir\\nAlice Fitoussi\\nAlien The DJ\\nAmaryllis Temmerman\\nAmbeon\\nAmina Alaoui\\nAmália Rodrigues\\nAn Pierlé\\nAnathema\\nAni DiFranco\\nAnkata\\nAnn Christy\\nAnne Clark\\nAphex Twin\\nAphex Twin/James\\nAphex Twin/Richard James\\nApolo Novax\\nArbeid Adelt!\\nArithmetic\\nArmand\\nArno\\nArt Of Noise\\nArte'\\nAsian Dub Foundation\\nAtmosfear Featuring Mae B.\\nAwilo feat. James D Train\\nAxelle Red\\nB-52's\\nBUIKA\\nBamada\\nBana Kin Percussions\\nBarbeton L.M.C.\\n\\\"Beach Boys, THE\\\"\\nBeastie Boys\\n\\\"Beatles, THE\\\"\\nBeautiful Pea Green Boat\\nBeirut Biloma\\nBenny Goodman\\nBenny Goodman \\u0026 His Orchestra\\nBert De Coninck\\nBisso Na Bisso\\nBlack Sabbath\\nBlondie\\n\\\"Boerenzonen op Speed, THE\\\"\\nBoni Gnahoré\\nBoudewijn de Groot\\nBoudewijn deGroot\\n\\\"Boyz from Brazil, THE\\\"\\nBoz Daya\\nBram Vermeulen\\nBuena Vista Social Club\\nCabaret Voltaire\\nCain Principle\\nCamouflage\\nCaptain Beefheart \\u0026 the Magic Band\\nCazima\\nChandeen\\n\\\"Charlatans, THE\\\"\\nCheikha Djenia\\nCheikha Remitti\\n\\\"Chemical Brothers, THE\\\"\\nClotaire K\\nColdplay\\nCrash Course In Science\\nCristina Vilallonga\\n\\\"Cure, THE\\\"\\nD.A.F.\\nDaan\\nDaby Touré\\nDavid Bowie\\nDavid Walters\\nDe Elegasten\\nDe Kreuners\\nDe Mens\\nDe Nieuwe Snaar\\nDe/Vision\\nDead Can Dance\\nDelerium\\nDella Bosiers\\nDella Bossiers\\nDepeche Mode\\nDimitri Van Toren\\nDire Straits\\nDoe Maar\\nEden\\nEl Fish\\nElie Attieh\\nEurythmics\\n\\\"Eurythmics, THE\\\"\\nEva De Roovere\\nEva de Roovere \\u0026 Gerry de Mol\\nExecutive Slacks\\nFad Gadget\\nFadela\\nFaith No More\\nFaithless\\nFats\\nFaudel\\nFernando Maurício\\nFischer-Z\\nFlash \\u0026 the pan\\nFrank Zappa\\nFrans Halsema \\u0026 Jenny Arean\\nFreestylers\\nFront 242\\nFulgence Compaoré\\nGadji Celi\\nGarbage\\nGary Numan\\n\\\"Gathering, THE\\\"\\nGhalia Benali\\nGoldfrapp\\nGorky\\nGotan Project\\nGrauzone\\nGuns N' Roses\\nGuru / DC Lee\\nGuy Manoukian\\nHans de Booij\\nHarem\\nHerman Brood \\u0026 Henny Vrienten\\nHoover\\nHooverphonic\\nHouria\\nHouse Of Pain\\nHugo Raspoet\\nHuman League\\nINXS\\nIggy Pop\\nIke \\u0026 Tina Turner\\nIsigq Samazulu\\nIvan Heylen\\nJan De Wilde\\nJan Puimege\\nJanis Joplin\\nJasmine Yee\\nJeff Buckley\\nJimi Hendrix Experience\\nJo Lemaire\\nJoelle Ursull\\nJohan Verminnen\\nJules De Corte\\nK's choice\\nKadril\\nKevin Mfinka\\nKim Wilde\\n\\\"Kinks, THE\\\"\\nKirpi\\nKoffi Olomide\\nKraftwerk\\nKris de Bruyne\\nLacuna Coil\\n\\\"Lamp, Lazarus \\u0026 Kris\\\"\\nLa´s\\nLed Zeppelin\\nLeftfield\\nLeki\\nLeonard Cohen\\nLes Parents Du Campus\\nLeslie feat Magic system\\u0026Sweety\\nLiesbeth List\\nLiesbeth List \\u0026 Ramses Shaffy\\nLine monty\\nLiquid Liquid\\nLive\\nLiving Colour\\nLouis Neefs\\nLove Is Colder than Death\\nLura\\nM.I.A.\\nMadonna\\nMagic System\\nMamany Kouyaté\\nMarc Moulin\\nMarianne Faithfull\\nMariza\\nMark Knopfler\\nMassive Attack\\nMeiway\\nMelike\\nMelonie Cannon\\nMercan Dede\\nMetallica\\nMidnight Oil\\nMiek en Roel\\nMiel Cools\\nMísia\\nNadia Ben Youcef\\nNatacha Atlas\\nNeeka\\nNeil Young\\nNew Order\\nNick Kamen\\nNightwish\\nNirvana\\nNitzer Ebb\\nNorah Jones\\nNoria\\n\\\"Normal, THE\\\"\\nNorthern Territories\\nNovastar\\nOasis\\nOblomov\\nOrient Funk\\nOsane\\nOuerdia\\nPJ Harvey\\nPapa Wemba\\nPascal DanaÚ\\nPatti Smith Group\\nPaul Van Vliet\\nPearl Jam\\nPendulum\\nPeter Schaap\\nPetit Yode \\u0026 L'Enfant Siro\\nPink Floyd\\nPixies\\n\\\"Police, THE\\\"\\nPraga Khan\\nPrefab Sprout\\n\\\"Pretenders, THE\\\"\\nPrimus\\nPrince\\nPsyche\\nPépé Kallé\\nQueen\\nR.E.G. Project\\nR.E.M.\\nRUM\\nRabah Khalfa\\nRadiohead\\nRage Against the Machine\\nRamses Shaffy\\nRaymond van het Groenewoud\\nRed Zebra\\nReinette l'Oranaise\\nRob De Nijs\\nSabahat Akkiraz\\nSaid M'Rad\\nSalif Keita\\nSam Mangwana\\nSans Papiers feat. Charlotte Mbango\\nSantana\\nSantana/Gypsy Queen\\nSara Tavares\\nSchriekback\\nScorpions\\nShape of Despair\\nSilence Gift\\nSilke Bischof\\nSimon \\u0026 Garfunkel\\nSimon and Garfunkel\\nSimple Minds\\nSisters of Mercy\\n\\\"Sisters of Mercy, THE\\\"\\nSkunk anansie\\nSmashing Pumpkins\\n\\\"Smashing Pumpkins, THE\\\"\\nSnowy Red\\nSois Belle\\nSouad\\nSouad Massi\\nSoukous Stars (Lokassa)\\nSoukous Stars (Zitany Neil)\\nSoul Swirling Somewhere\\nSoulsister\\nSpandau ballet\\nStereo Action Unlimited\\nStijn\\nSubcomandante Marcos\\nSusheela Raman\\nTalking Heads\\nTambours Du Burundi\\nTaoues\\nTechnotronic\\nTerence Trent d'Arby\\nTexas\\nTheatre of Tragedy\\nTherapy?\\nThé Lau \\u0026 Sarah Bettens\\nTori Amos\\nTransglobal Underground\\nTristania\\nTwice A Man\\nU2\\nUnderworld\\nUrbanus\\nVarious Artists\\nVaya Con Dios\\nVicious Pink\\nWalter De Buck\\nWannes Van De Velde\\nWarda\\n\\\"Waterboys, THE\\\"\\nWhite Rose Transmission\\n\\\"White Stripes, THE\\\"\\nWill Ferdy\\nWillem Vermandere\\nWim De Craene\\nWim Sonneveld\\nWithin Temptation\\nYasmina\\nYello\\nZjef Vanuytsel\\nZulu Bamba\\ndEUS\\nlieven tavernier\\nolla vogala\\n\\\"scene, THE\\\"\",\"format\":\"csv\",\"messages\":[{\"format\":\"callout-danger\",\"description\":\"Een of meerdere verwachte kolommen ontbreken. De ingediende query heeft 0 (verplichte) kolommen terwijl er 1 kolommen nodig zijn. De ontbrekende kolommen zijn: name\"}],\"generated\":\"substr\\n Lau \\u0026 Sarah Bettens\\nanus\\nter De Buck\\nda\\nl Ferdy\\nlem Vermandere\\n De Craene\\n Sonneveld\\nmina\\nf Vanuytsel\\nen The DJ\\nlia Rodrigues\\nex Twin\\nand\\nt De Coninck\\nm Vermeulen\\nikha Djenia\\nn\\nid Bowie\\nla Bossiers\\n De Roovere\\nnk Zappa\\nji Celi\\nu / DC Lee\\nria\\ny Pop\\ngq Samazulu\\nis Joplin\\nlle Ursull\\nril\\n Wilde\\ns de Bruyne\\nsbeth List\\na\\n.A.\\nc Moulin\\nk Knopfler\\ncan Dede\\nia Ben Youcef\\nah Jones\\ncal DanaÚ\\nit Yode \\u0026 L'Enfant Siro\\nses Shaffy\\nahat Akkiraz\\ntana\\na Tavares\\nad\\njn\\nues\\ni Amos\\nnes Van De Velde\\nlle Red\\nullah Chhadeh\\nikan Boy\\nce Fitoussi\\nryllis Temmerman\\nna Alaoui\\nPierlé\\n DiFranco\\n Christy\\nex Twin/James\\nex Twin/Richard James\\no\\ni Gnahoré\\ndewijn de Groot\\ndewijn deGroot\\nKA\\nndeen\\nikha Remitti\\ntaire K\\nstina Vilallonga\\ny Touré\\nid Walters\\nla Bosiers\\nitri Van Toren\\ne Attieh\\n de Roovere \\u0026 Gerry de Mol\\ndel\\nnando Maurício\\nns Halsema \\u0026 Jenny Arean\\ngence Compaoré\\ny Numan\\nlia Benali\\n Manoukian\\ns de Booij\\nman Brood \\u0026 Henny Vrienten\\no Raspoet\\n \\u0026 Tina Turner\\nn Heylen\\n De Wilde\\n Puimege\\nmine Yee\\nf Buckley\\nLemaire\\nan Verminnen\\nes De Corte\\nin Mfinka\\npi\\nfi Olomide\\ni\\nnard Cohen\\nlie feat Magic system\\u0026Sweety\\nsbeth List \\u0026 Ramses Shaffy\\nven tavernier\\nis Neefs\\nonna\\nany Kouyaté\\nianne Faithfull\\niza\\nike\\nonie Cannon\\nk en Roel\\nl Cools\\nia\\nacha Atlas\\nl Young\\nk Kamen\\nia\\na Wemba\\nl Van Vliet\\ner Schaap\\nHarvey\\nfab Sprout\\nnce\\né Kallé\\nah Khalfa\\nmond van het Groenewoud\\nnette l'Oranaise\\n De Nijs\\nd M'Rad\\nif Keita\\n Mangwana\\ntana/Gypsy Queen\\nke Bischof\\non \\u0026 Garfunkel\\non and Garfunkel\\nad Massi\\nheela Raman\\nking Heads\\nbours Du Burundi\\nhnotronic\\nence Trent d'Arby\\nas\\n Boerenzonen op Speed\\n Boyz from Brazil\\n Charlatans\\n Chemical Brothers\\n Gathering\\n Kinks\\n Normal\\n Police\\n Sisters of Mercy\\n Smashing Pumpkins\\n Waterboys\\nrapy?\\nnsglobal Underground\\nstania\\nce A Man\\n\\nerworld\\nious Artists\\nte Rose Transmission\\nhin Temptation\\nlo\\nu Bamba\\nwy Red\\ns Belle\\nndau ballet\\nreo Action Unlimited\\n Beach Boys\\n Beatles\\n Cure\\n Eurythmics\\n Pretenders\\n scene\\n White Stripes\\natre of Tragedy\\na Con Dios\\nious Pink\\nda\\n0 Ohm\\n1 Night Society\\nays In Egypt\\nutou Roots\\nDC\\niral Freebee\\nicanism All Stars\\no Celt Sound System\\ner Forever\\n\\neon\\nthema\\nata\\ne Clark\\nlo Novax\\neid Adelt!\\nthmetic\\n Of Noise\\ne'\\nan Dub Foundation\\nosfear Featuring Mae B.\\nlo feat. James D Train\\n2's\\nada\\na Kin Percussions\\nbeton L.M.C.\\nstie Boys\\nutiful Pea Green Boat\\nrut Biloma\\nny Goodman\\nny Goodman \\u0026 His Orchestra\\nso Na Bisso\\nck Sabbath\\nndie\\n Daya\\nna Vista Social Club\\naret Voltaire\\nn Principle\\nouflage\\ntain Beefheart \\u0026 the Magic Band\\nima\\ndplay\\nsh Course In Science\\n.F.\\nElegasten\\nKreuners\\nMens\\nNieuwe Snaar\\nVision\\nd Can Dance\\nerium\\neche Mode\\nS\\ne Straits\\n Maar\\nn\\nFish\\nythmics\\ncutive Slacks\\n Gadget\\nela\\nth No More\\nthless\\ns\\ncher-Z\\nsh \\u0026 the pan\\nestylers\\nnt 242\\nbage\\ndfrapp\\nky\\nan Project\\nuzone\\ns N' Roses\\nem\\nver\\nverphonic\\nse Of Pain\\nan League\\nS\\ni Hendrix Experience\\nftwerk\\n choice\\ns\\nuna Coil\\n\\\"p, Lazarus \\u0026 Kris\\\"\\n Zeppelin\\ntfield\\n Parents Du Campus\\ne monty\\nuid Liquid\\ne\\ning Colour\\ne Is Colder than Death\\nic System\\nsive Attack\\nway\\nallica\\nnight Oil\\nka\\n Order\\nhtwish\\nvana\\nzer Ebb\\nthern Territories\\nastar\\nis\\nomov\\na vogala\\nent Funk\\nne\\nrdia\\nti Smith Group\\nrl Jam\\ndulum\\nk Floyd\\nies\\nga Khan\\nmus\\nche\\nen\\n.G. Project\\n.M.\\niohead\\ne Against the Machine\\n Zebra\\n\\ns Papiers feat. Charlotte Mbango\\nriekback\\nrpions\\npe of Despair\\nence Gift\\nple Minds\\nters of Mercy\\nnk anansie\\nshing Pumpkins\\nkous Stars (Lokassa)\\nkous Stars (Zitany Neil)\\nl Swirling Somewhere\\nlsister\\ncomandante Marcos\",\"accepted\":false}]}]},{\"accepted\":false,\"groups\":[{\"description\":\"Data types vergelijken\",\"accepted\":false,\"tests\":[{\"expected\":\"column,type\\nname,VARCHAR\",\"format\":\"csv\",\"generated\":\"column,type\\nsubstr,VARCHAR\",\"accepted\":false}]}]},{\"accepted\":false,\"groups\":[{\"description\":\"Rij volgorde vergelijken\",\"accepted\":false,\"tests\":[{\"expected\":\"correcte volgorde\",\"messages\":[{\"format\":\"callout-danger\",\"description\":\"De volgorde van de rijen is niet correct. Bekijk nauwgezet de opgave zodat je zeker niets gemist hebt. Om op een betrouwbare manier het verschil tussen de indiening en de modeloplossing te tonen, is de volgorde van rijen op dit tabblad niet (altijd) gelijk aan de volgorde die jij hebt opgegeven. Op het tabblad 'Volledig Resultaat' kan je de exacte resultaten (en volgorde) van je ingediende query bekijken.\"}],\"generated\":\"incorrecte volgorde\",\"accepted\":false}]}]}]},{\"description\":\"Volledig Resultaat\",\"badgeCount\":0,\"groups\":[{\"accepted\":true,\"groups\":[{\"description\":\"Volledig query resultaat\",\"accepted\":true,\"tests\":[{\"expected\":\"\",\"format\":\"csv\",\"generated\":\"substr\\n Lau \\u0026 Sarah Bettens\\nanus\\nter De Buck\\nda\\nl Ferdy\\nlem Vermandere\\n De Craene\\n Sonneveld\\nmina\\nf Vanuytsel\\nen The DJ\\nlia Rodrigues\\nex Twin\\nand\\nt De Coninck\\nm Vermeulen\\nikha Djenia\\nn\\nid Bowie\\nla Bossiers\\n De Roovere\\nnk Zappa\\nji Celi\\nu / DC Lee\\nria\\ny Pop\\ngq Samazulu\\nis Joplin\\nlle Ursull\\nril\\n Wilde\\ns de Bruyne\\nsbeth List\\na\\n.A.\\nc Moulin\\nk Knopfler\\ncan Dede\\nia Ben Youcef\\nah Jones\\ncal DanaÚ\\nit Yode \\u0026 L'Enfant Siro\\nses Shaffy\\nahat Akkiraz\\ntana\\na Tavares\\nad\\njn\\nues\\ni Amos\\nnes Van De Velde\\nlle Red\\nullah Chhadeh\\nikan Boy\\nce Fitoussi\\nryllis Temmerman\\nna Alaoui\\nPierlé\\n DiFranco\\n Christy\\nex Twin/James\\nex Twin/Richard James\\no\\ni Gnahoré\\ndewijn de Groot\\ndewijn deGroot\\nKA\\nndeen\\nikha Remitti\\ntaire K\\nstina Vilallonga\\ny Touré\\nid Walters\\nla Bosiers\\nitri Van Toren\\ne Attieh\\n de Roovere \\u0026 Gerry de Mol\\ndel\\nnando Maurício\\nns Halsema \\u0026 Jenny Arean\\ngence Compaoré\\ny Numan\\nlia Benali\\n Manoukian\\ns de Booij\\nman Brood \\u0026 Henny Vrienten\\no Raspoet\\n \\u0026 Tina Turner\\nn Heylen\\n De Wilde\\n Puimege\\nmine Yee\\nf Buckley\\nLemaire\\nan Verminnen\\nes De Corte\\nin Mfinka\\npi\\nfi Olomide\\ni\\nnard Cohen\\nlie feat Magic system\\u0026Sweety\\nsbeth List \\u0026 Ramses Shaffy\\nven tavernier\\nis Neefs\\nonna\\nany Kouyaté\\nianne Faithfull\\niza\\nike\\nonie Cannon\\nk en Roel\\nl Cools\\nia\\nacha Atlas\\nl Young\\nk Kamen\\nia\\na Wemba\\nl Van Vliet\\ner Schaap\\nHarvey\\nfab Sprout\\nnce\\né Kallé\\nah Khalfa\\nmond van het Groenewoud\\nnette l'Oranaise\\n De Nijs\\nd M'Rad\\nif Keita\\n Mangwana\\ntana/Gypsy Queen\\nke Bischof\\non \\u0026 Garfunkel\\non and Garfunkel\\nad Massi\\nheela Raman\\nking Heads\\nbours Du Burundi\\nhnotronic\\nence Trent d'Arby\\nas\\n Boerenzonen op Speed\\n Boyz from Brazil\\n Charlatans\\n Chemical Brothers\\n Gathering\\n Kinks\\n Normal\\n Police\\n Sisters of Mercy\\n Smashing Pumpkins\\n Waterboys\\nrapy?\\nnsglobal Underground\\nstania\\nce A Man\\n\\nerworld\\nious Artists\\nte Rose Transmission\\nhin Temptation\\nlo\\nu Bamba\\nwy Red\\ns Belle\\nndau ballet\\nreo Action Unlimited\\n Beach Boys\\n Beatles\\n Cure\\n Eurythmics\\n Pretenders\\n scene\\n White Stripes\\natre of Tragedy\\na Con Dios\\nious Pink\\nda\\n0 Ohm\\n1 Night Society\\nays In Egypt\\nutou Roots\\nDC\\niral Freebee\\nicanism All Stars\\no Celt Sound System\\ner Forever\\n\\neon\\nthema\\nata\\ne Clark\\nlo Novax\\neid Adelt!\\nthmetic\\n Of Noise\\ne'\\nan Dub Foundation\\nosfear Featuring Mae B.\\nlo feat. James D Train\\n2's\\nada\\na Kin Percussions\\nbeton L.M.C.\\nstie Boys\\nutiful Pea Green Boat\\nrut Biloma\\nny Goodman\\nny Goodman \\u0026 His Orchestra\\nso Na Bisso\\nck Sabbath\\nndie\\n Daya\\nna Vista Social Club\\naret Voltaire\\nn Principle\\nouflage\\ntain Beefheart \\u0026 the Magic Band\\nima\\ndplay\\nsh Course In Science\\n.F.\\nElegasten\\nKreuners\\nMens\\nNieuwe Snaar\\nVision\\nd Can Dance\\nerium\\neche Mode\\nS\\ne Straits\\n Maar\\nn\\nFish\\nythmics\\ncutive Slacks\\n Gadget\\nela\\nth No More\\nthless\\ns\\ncher-Z\\nsh \\u0026 the pan\\nestylers\\nnt 242\\nbage\\ndfrapp\\nky\\nan Project\\nuzone\\ns N' Roses\\nem\\nver\\nverphonic\\nse Of Pain\\nan League\\nS\\ni Hendrix Experience\\nftwerk\\n choice\\ns\\nuna Coil\\n\\\"p, Lazarus \\u0026 Kris\\\"\\n Zeppelin\\ntfield\\n Parents Du Campus\\ne monty\\nuid Liquid\\ne\\ning Colour\\ne Is Colder than Death\\nic System\\nsive Attack\\nway\\nallica\\nnight Oil\\nka\\n Order\\nhtwish\\nvana\\nzer Ebb\\nthern Territories\\nastar\\nis\\nomov\\na vogala\\nent Funk\\nne\\nrdia\\nti Smith Group\\nrl Jam\\ndulum\\nk Floyd\\nies\\nga Khan\\nmus\\nche\\nen\\n.G. Project\\n.M.\\niohead\\ne Against the Machine\\n Zebra\\n\\ns Papiers feat. Charlotte Mbango\\nriekback\\nrpions\\npe of Despair\\nence Gift\\nple Minds\\nters of Mercy\\nnk anansie\\nshing Pumpkins\\nkous Stars (Lokassa)\\nkous Stars (Zitany Neil)\\nl Swirling Somewhere\\nlsister\\ncomandante Marcos\",\"accepted\":true}]}]}]}],\"messages\":[{\"format\":\"html\",\"description\":\"\\u003cstrong\\u003eWorker:\\u003c/strong\\u003e tantalus\",\"permission\":\"zeus\"},{\"format\":\"html\",\"description\":\"\\u003cstrong\\u003eMemory usage:\\u003c/strong\\u003e 44.05 MiB\",\"permission\":\"zeus\"},{\"format\":\"html\",\"description\":\"\\u003cstrong\\u003ePrepare:\\u003c/strong\\u003e 0.19 seconds\",\"permission\":\"zeus\"},{\"format\":\"html\",\"description\":\"\\u003cstrong\\u003eRuntime:\\u003c/strong\\u003e 0.92 seconds\",\"permission\":\"zeus\"},{\"format\":\"html\",\"description\":\"\\u003cstrong\\u003eResult construction:\\u003c/strong\\u003e 0.01 seconds\",\"permission\":\"zeus\"},{\"format\":\"html\",\"description\":\"\\u003cstrong\\u003eFinalize:\\u003c/strong\\u003e 0.03 seconds\",\"permission\":\"zeus\"},{\"format\":\"html\",\"description\":\"\\u003cstrong\\u003eTotal time:\\u003c/strong\\u003e 1.25 seconds\",\"permission\":\"zeus\"}]}"

    sign_in submission.user
    get submission_path(submission)

    assert_response :ok
  end

  test 'Should be able to render submission with malformed csv' do
    submission = create :wrong_submission, code: 'select * from track where trackid = 1610',
                                           result: '{"accepted":false,"status":"wrong","description":"Test failed","annotations":[{"text":"An SQL query should end with a semicolon","type":"info","row":1,"rows":1,"column":null,"columns":null,"externalUrl":null}],"groups":[{"description":"Result Validation","badgeCount":2,"groups":[{"accepted":false,"groups":[{"description":"Compare results","accepted":false,"tests":[{"expected":"\"title\"\\n\"Grace\"\\n\"Monster\"\\n\"The Greatest Hits\"\\n\"Throwing Copper\"\\n\"Toward the Within\"\\n\"Troublegum\"\\n\"Worst Case Scenario\"","format":"csv","messages":[{"format":"callout-danger","description":"Incorrect row count"}],"generated":"\"title\",\"trackid\",\"genre\",\"albumid\",\"artistid\",\"tracknumber\"\\n\"\"So Fast, So Numb\"\",\"1610\",\"Rock\",\"523\",\"229\",\"12\"","accepted":false}]}]},{"accepted":true,"groups":[{"description":"Column Types","accepted":true,"tests":[{"expected":"\"column\",\"type\"\\n\"title\",\"STRING\"","format":"csv","generated":"\"column\",\"type\"\\n\"title\",\"STRING\"\\n\"trackid\",\"INTEGER\"\\n\"genre\",\"STRING\"\\n\"albumid\",\"INTEGER\"\\n\"artistid\",\"INTEGER\"\\n\"tracknumber\",\"INTEGER\"","accepted":true}]}]},{"accepted":false,"groups":[{"description":"Order By","accepted":false,"tests":[{"expected":"correct order","generated":"incorrect order","accepted":false}]}]}]},{"description":"Query Result","badgeCount":0,"groups":[{"accepted":true,"groups":[{"description":"Full result","accepted":true,"tests":[{"expected":"","format":"csv","generated":"\"title\",\"trackid\",\"genre\",\"albumid\",\"artistid\",\"tracknumber\"\\n\"\"So Fast, So Numb\"\",\"1610\",\"Rock\",\"523\",\"229\",\"12\"","accepted":true}]}]}]}],"messages":[{"format":"html","description":"\\u003cstrong\\u003eWorker:\\u003c/strong\\u003e ixion","permission":"zeus"},{"format":"html","description":"\\u003cstrong\\u003eMemory usage:\\u003c/strong\\u003e 40.61 MiB","permission":"zeus"},{"format":"html","description":"\\u003cstrong\\u003ePrepare:\\u003c/strong\\u003e 0.13 seconds","permission":"zeus"},{"format":"html","description":"\\u003cstrong\\u003eRuntime:\\u003c/strong\\u003e 0.92 seconds","permission":"zeus"},{"format":"html","description":"\\u003cstrong\\u003eResult construction:\\u003c/strong\\u003e 0.02 seconds","permission":"zeus"},{"format":"html","description":"\\u003cstrong\\u003eFinalize:\\u003c/strong\\u003e 0.01 seconds","permission":"zeus"},{"format":"html","description":"\\u003cstrong\\u003eTotal time:\\u003c/strong\\u003e 1.14 seconds","permission":"zeus"}]}'
    sign_in submission.user
    get submission_path(submission)

    assert_response :ok
  end

  test 'should not be able to submit to invalid exercise' do
    attrs = generate_attr_hash
    exercise = Exercise.find(attrs[:exercise_id])
    exercise.update!(status: :not_valid)

    sign_in create(:staff)
    create_request(attr_hash: attrs)

    assert_response :unprocessable_entity
  end

  test 'should not be able to submit to valid exercise' do
    attrs = generate_attr_hash

    sign_in create(:staff)
    create_request(attr_hash: attrs)

    assert_response :success
  end
end
