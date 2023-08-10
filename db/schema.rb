# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_07_13_073547) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata", size: :medium
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name_nl"
    t.string "name_en"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "path"
    t.string "description_format"
    t.integer "repository_id"
    t.integer "judge_id"
    t.integer "status", default: 0
    t.integer "access", default: 0, null: false
    t.bigint "programming_language_id"
    t.string "search", limit: 4096
    t.string "access_token", limit: 16, null: false
    t.string "repository_token", limit: 64, null: false
    t.boolean "allow_unsafe", default: false, null: false
    t.string "type", default: "Exercise", null: false
    t.boolean "description_nl_present", default: false
    t.boolean "description_en_present", default: false
    t.integer "series_count", default: 0, null: false
    t.index ["judge_id"], name: "index_activities_on_judge_id"
    t.index ["name_nl"], name: "index_activities_on_name_nl"
    t.index ["path", "repository_id"], name: "index_activities_on_path_and_repository_id", unique: true
    t.index ["programming_language_id"], name: "fk_rails_f60feebafd"
    t.index ["repository_id"], name: "index_activities_on_repository_id"
    t.index ["repository_token"], name: "index_activities_on_repository_token", unique: true
    t.index ["status"], name: "index_activities_on_status"
  end

  create_table "activity_labels", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.bigint "label_id", null: false
    t.index ["activity_id", "label_id"], name: "index_activity_labels_on_activity_id_and_label_id", unique: true
    t.index ["label_id"], name: "fk_rails_0510a660e5"
  end

  create_table "activity_read_states", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.integer "course_id"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id", "course_id", "user_id"], name: "activity_read_states_unique", unique: true
    t.index ["course_id"], name: "fk_rails_f674cacc14"
    t.index ["user_id"], name: "fk_rails_96d00253e9"
  end

  create_table "activity_statuses", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.boolean "accepted", default: false, null: false
    t.boolean "accepted_before_deadline", default: false, null: false
    t.boolean "solved", default: false, null: false
    t.boolean "started", default: false, null: false
    t.datetime "solved_at", precision: nil
    t.integer "activity_id", null: false
    t.integer "series_id"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_submission_id"
    t.integer "last_submission_deadline_id"
    t.integer "best_submission_id"
    t.integer "best_submission_deadline_id"
    t.integer "series_id_non_nil", null: false
    t.index ["accepted", "user_id", "series_id"], name: "index_activity_statuses_on_accepted_and_user_id_and_series_id"
    t.index ["activity_id"], name: "index_activity_statuses_on_activity_id"
    t.index ["series_id"], name: "fk_rails_1bc42c2178"
    t.index ["started", "user_id", "last_submission_id"], name: "index_as_on_started_and_user_and_last_submission"
    t.index ["started", "user_id", "series_id"], name: "index_activity_statuses_on_started_and_user_id_and_series_id"
    t.index ["user_id", "series_id", "last_submission_id"], name: "index_as_on_user_and_series_and_last_submission"
    t.index ["user_id", "series_id_non_nil", "activity_id"], name: "index_on_user_id_series_id_non_nil_activity_id", unique: true
  end

  create_table "annotations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "line_nr"
    t.integer "submission_id"
    t.integer "user_id"
    t.text "annotation_text", size: :medium
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "evaluation_id"
    t.string "type", default: "Annotation", null: false
    t.integer "question_state"
    t.integer "last_updated_by_id", null: false
    t.integer "course_id", null: false
    t.bigint "saved_annotation_id"
    t.integer "thread_root_id"
    t.integer "column"
    t.integer "rows", default: 1, null: false
    t.integer "columns"
    t.index ["course_id", "type", "question_state"], name: "index_annotations_on_course_id_and_type_and_question_state"
    t.index ["evaluation_id"], name: "index_annotations_on_evaluation_id"
    t.index ["last_updated_by_id"], name: "index_annotations_on_last_updated_by_id"
    t.index ["saved_annotation_id"], name: "index_annotations_on_saved_annotation_id"
    t.index ["submission_id"], name: "index_annotations_on_submission_id"
    t.index ["user_id"], name: "index_annotations_on_user_id"
  end

  create_table "announcement_views", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "announcement_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_id"], name: "index_announcement_views_on_announcement_id"
    t.index ["user_id", "announcement_id"], name: "index_announcement_views_on_user_id_and_announcement_id", unique: true
    t.index ["user_id"], name: "index_announcement_views_on_user_id"
  end

  create_table "announcements", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.text "text_nl", null: false
    t.text "text_en", null: false
    t.datetime "start_delivering_at"
    t.datetime "stop_delivering_at"
    t.integer "user_group", null: false
    t.bigint "institution_id"
    t.integer "style", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["institution_id"], name: "index_announcements_on_institution_id"
  end

  create_table "api_tokens", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id"
    t.string "token_digest"
    t.string "description"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest"
    t.index ["user_id", "description"], name: "index_api_tokens_on_user_id_and_description", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "course_labels", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["course_id", "name"], name: "index_course_labels_on_course_id_and_name", unique: true
  end

  create_table "course_membership_labels", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_membership_id", null: false
    t.bigint "course_label_id", null: false
    t.index ["course_label_id", "course_membership_id"], name: "unique_label_and_course_membership_index", unique: true
    t.index ["course_membership_id"], name: "fk_rails_7d6a6611cf"
  end

  create_table "course_memberships", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "user_id", null: false
    t.integer "status", default: 2, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "favorite", default: false
    t.index ["course_id"], name: "index_course_memberships_on_course_id"
    t.index ["user_id", "course_id"], name: "index_course_memberships_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_course_memberships_on_user_id"
  end

  create_table "course_repositories", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "repository_id", null: false
    t.index ["course_id", "repository_id"], name: "index_course_repositories_on_course_id_and_repository_id", unique: true
    t.index ["repository_id"], name: "fk_rails_4d1393e517"
  end

  create_table "courses", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "year"
    t.string "secret"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.text "description", size: :long
    t.integer "visibility", default: 0
    t.integer "registration", default: 0
    t.string "teacher"
    t.bigint "institution_id"
    t.string "search", limit: 4096
    t.boolean "moderated", default: false, null: false
    t.boolean "enabled_questions", default: true, null: false
    t.boolean "featured", default: false, null: false
    t.index ["featured"], name: "index_courses_on_featured"
    t.index ["institution_id"], name: "index_courses_on_institution_id"
  end

  create_table "delayed_jobs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", size: :long, null: false
    t.text "last_error", size: :long
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "evaluation_exercises", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "evaluation_id"
    t.integer "exercise_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible_score", default: true, null: false
    t.index ["evaluation_id"], name: "index_evaluation_exercises_on_evaluation_id"
    t.index ["exercise_id", "evaluation_id"], name: "index_evaluation_exercises_on_exercise_id_and_evaluation_id", unique: true
    t.index ["exercise_id"], name: "index_evaluation_exercises_on_exercise_id"
  end

  create_table "evaluation_users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "evaluation_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evaluation_id"], name: "index_evaluation_users_on_evaluation_id"
    t.index ["user_id", "evaluation_id"], name: "index_evaluation_users_on_user_id_and_evaluation_id", unique: true
    t.index ["user_id"], name: "index_evaluation_users_on_user_id"
  end

  create_table "evaluations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "series_id"
    t.boolean "released", default: false, null: false
    t.datetime "deadline", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["series_id"], name: "index_evaluations_on_unique_series_id", unique: true
  end

  create_table "events", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "event_type", null: false
    t.integer "user_id"
    t.string "message", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["user_id"], name: "fk_rails_0cb5590091"
  end

  create_table "exports", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_exports_on_user_id"
  end

  create_table "feedbacks", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "submission_id"
    t.bigint "evaluation_id"
    t.bigint "evaluation_user_id"
    t.bigint "evaluation_exercise_id"
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evaluation_exercise_id"], name: "index_feedbacks_on_evaluation_exercise_id"
    t.index ["evaluation_id"], name: "index_feedbacks_on_evaluation_id"
    t.index ["evaluation_user_id"], name: "index_feedbacks_on_evaluation_user_id"
    t.index ["submission_id"], name: "index_feedbacks_on_submission_id"
  end

  create_table "identities", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "identifier", null: false
    t.bigint "provider_id", null: false
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "identifier_based_on_email", default: false, null: false
    t.boolean "identifier_based_on_username", default: false, null: false
    t.index ["provider_id", "identifier"], name: "index_identities_on_provider_id_and_identifier", unique: true
    t.index ["provider_id", "user_id"], name: "index_identities_on_provider_id_and_user_id", unique: true
    t.index ["user_id"], name: "fk_rails_5373344100"
  end

  create_table "institutions", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.string "logo"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "generated_name", default: true, null: false
    t.integer "category", default: 0, null: false
  end

  create_table "judges", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.string "path"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "renderer", null: false
    t.string "remote"
    t.integer "clone_status", default: 1, null: false
    t.index ["name"], name: "index_judges_on_name", unique: true
  end

  create_table "labels", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "color", null: false
    t.index ["name"], name: "index_labels_on_name", unique: true
  end

  create_table "notifications", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "message", null: false
    t.boolean "read", default: false, null: false
    t.integer "user_id", null: false
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "programming_languages", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "editor_name", null: false
    t.string "extension", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "icon"
    t.string "renderer_name", null: false
    t.index ["name"], name: "index_programming_languages_on_name", unique: true
  end

  create_table "providers", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "type", default: "Provider::Saml", null: false
    t.bigint "institution_id"
    t.string "identifier"
    t.text "certificate", size: :medium
    t.string "entity_id"
    t.string "slo_url"
    t.string "sso_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "mode", default: 0, null: false
    t.boolean "active", default: true
    t.string "authorization_uri"
    t.string "client_id"
    t.string "issuer"
    t.string "jwks_uri"
    t.index ["institution_id"], name: "fk_rails_ba691498dd"
  end

  create_table "repositories", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "name"
    t.string "remote"
    t.string "path"
    t.integer "judge_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "clone_status", default: 1, null: false
    t.boolean "featured", default: false
    t.index ["judge_id"], name: "index_repositories_on_judge_id"
    t.index ["name"], name: "index_repositories_on_name", unique: true
    t.index ["path"], name: "index_repositories_on_path", unique: true
  end

  create_table "repository_admins", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "repository_id", null: false
    t.integer "user_id", null: false
    t.index ["repository_id", "user_id"], name: "index_repository_admins_on_repository_id_and_user_id", unique: true
    t.index ["user_id"], name: "fk_rails_6b59ad362c"
  end

  create_table "rights_requests", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "institution_name"
    t.text "context", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_rights_requests_on_user_id"
  end

  create_table "saved_annotations", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "title", null: false
    t.text "annotation_text", size: :medium
    t.integer "user_id", null: false
    t.integer "exercise_id", null: false
    t.integer "course_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "annotations_count", default: 0
    t.index ["course_id"], name: "index_saved_annotations_on_course_id"
    t.index ["exercise_id"], name: "index_saved_annotations_on_exercise_id"
    t.index ["title", "user_id", "exercise_id", "course_id"], name: "index_saved_annotations_title_uid_eid_cid", unique: true
    t.index ["user_id"], name: "index_saved_annotations_on_user_id"
  end

  create_table "score_items", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "evaluation_exercise_id", null: false
    t.decimal "maximum", precision: 5, scale: 2, null: false
    t.string "name", null: false
    t.boolean "visible", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evaluation_exercise_id"], name: "index_score_items_on_evaluation_exercise_id"
  end

  create_table "scores", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "score_item_id", null: false
    t.bigint "feedback_id", null: false
    t.decimal "score", precision: 5, scale: 2, null: false
    t.integer "last_updated_by_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feedback_id"], name: "index_scores_on_feedback_id"
    t.index ["last_updated_by_id"], name: "index_scores_on_last_updated_by_id"
    t.index ["score_item_id", "feedback_id"], name: "index_scores_on_score_item_id_and_feedback_id", unique: true
    t.index ["score_item_id"], name: "index_scores_on_score_item_id"
  end

  create_table "series", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "course_id"
    t.string "name"
    t.text "description", size: :long
    t.integer "visibility"
    t.integer "order", default: 0, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.datetime "deadline", precision: nil
    t.string "access_token"
    t.boolean "progress_enabled", default: true, null: false
    t.boolean "activities_visible", default: true, null: false
    t.integer "activities_count"
    t.boolean "activity_numbers_enabled", default: false, null: false
    t.index ["access_token"], name: "index_series_on_access_token"
    t.index ["course_id"], name: "index_series_on_course_id"
    t.index ["deadline"], name: "index_series_on_deadline"
    t.index ["name"], name: "index_series_on_name"
    t.index ["visibility"], name: "index_series_on_visibility"
  end

  create_table "series_memberships", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "series_id"
    t.integer "activity_id"
    t.integer "order", default: 999
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["activity_id"], name: "index_series_memberships_on_activity_id"
    t.index ["series_id", "activity_id"], name: "index_series_memberships_on_series_id_and_activity_id", unique: true
    t.index ["series_id"], name: "index_series_memberships_on_series_id"
  end

  create_table "submissions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.integer "exercise_id"
    t.integer "user_id"
    t.string "summary"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "status"
    t.boolean "accepted", default: false
    t.integer "course_id"
    t.string "fs_key", limit: 24
    t.integer "number"
    t.boolean "annotated", default: false, null: false
    t.index ["accepted"], name: "index_submissions_on_accepted"
    t.index ["course_id"], name: "index_submissions_on_course_id"
    t.index ["exercise_id", "status", "course_id"], name: "ex_st_co_idx"
    t.index ["exercise_id", "user_id", "accepted", "created_at"], name: "ex_us_ac_cr_index"
    t.index ["exercise_id", "user_id", "status", "created_at"], name: "ex_us_st_cr_index"
    t.index ["exercise_id"], name: "index_submissions_on_exercise_id"
    t.index ["fs_key"], name: "index_submissions_on_fs_key", unique: true
    t.index ["status"], name: "index_submissions_on_status"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "username"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.integer "permission", default: 0
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "lang", default: "nl"
    t.string "token"
    t.string "time_zone", default: "Brussels"
    t.bigint "institution_id"
    t.string "search", limit: 4096
    t.datetime "seen_at", precision: nil
    t.datetime "sign_in_at", precision: nil
    t.integer "open_questions_count", default: 0, null: false
    t.integer "theme", default: 0, null: false
    t.index ["email", "institution_id"], name: "index_users_on_email_and_institution_id", unique: true
    t.index ["institution_id"], name: "index_users_on_institution_id"
    t.index ["token"], name: "index_users_on_token"
    t.index ["username", "institution_id"], name: "index_users_on_username_and_institution_id", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "judges"
  add_foreign_key "activities", "programming_languages"
  add_foreign_key "activities", "repositories"
  add_foreign_key "activity_labels", "activities"
  add_foreign_key "activity_labels", "labels"
  add_foreign_key "activity_read_states", "activities", on_delete: :cascade
  add_foreign_key "activity_read_states", "courses", on_delete: :cascade
  add_foreign_key "activity_read_states", "users", on_delete: :cascade
  add_foreign_key "activity_statuses", "activities", on_delete: :cascade
  add_foreign_key "activity_statuses", "series", on_delete: :cascade
  add_foreign_key "activity_statuses", "users", on_delete: :cascade
  add_foreign_key "annotations", "courses"
  add_foreign_key "annotations", "evaluations"
  add_foreign_key "annotations", "saved_annotations"
  add_foreign_key "annotations", "submissions"
  add_foreign_key "annotations", "users"
  add_foreign_key "annotations", "users", column: "last_updated_by_id"
  add_foreign_key "announcement_views", "announcements"
  add_foreign_key "announcement_views", "users"
  add_foreign_key "announcements", "institutions"
  add_foreign_key "course_labels", "courses", on_delete: :cascade
  add_foreign_key "course_membership_labels", "course_labels", on_delete: :cascade
  add_foreign_key "course_membership_labels", "course_memberships", on_delete: :cascade
  add_foreign_key "course_memberships", "courses", on_delete: :cascade
  add_foreign_key "course_memberships", "users", on_delete: :cascade
  add_foreign_key "course_repositories", "courses"
  add_foreign_key "course_repositories", "repositories"
  add_foreign_key "courses", "institutions"
  add_foreign_key "evaluation_exercises", "activities", column: "exercise_id"
  add_foreign_key "evaluation_exercises", "evaluations"
  add_foreign_key "evaluation_users", "evaluations"
  add_foreign_key "evaluation_users", "users"
  add_foreign_key "evaluations", "series"
  add_foreign_key "events", "users", on_delete: :cascade
  add_foreign_key "exports", "users"
  add_foreign_key "feedbacks", "evaluation_exercises"
  add_foreign_key "feedbacks", "evaluation_users"
  add_foreign_key "feedbacks", "evaluations"
  add_foreign_key "feedbacks", "submissions"
  add_foreign_key "identities", "providers", on_delete: :cascade
  add_foreign_key "identities", "users", on_delete: :cascade
  add_foreign_key "notifications", "users"
  add_foreign_key "providers", "institutions", on_delete: :cascade
  add_foreign_key "repositories", "judges"
  add_foreign_key "repository_admins", "repositories"
  add_foreign_key "repository_admins", "users"
  add_foreign_key "rights_requests", "users"
  add_foreign_key "saved_annotations", "activities", column: "exercise_id"
  add_foreign_key "saved_annotations", "courses"
  add_foreign_key "saved_annotations", "users"
  add_foreign_key "score_items", "evaluation_exercises"
  add_foreign_key "scores", "feedbacks"
  add_foreign_key "scores", "score_items"
  add_foreign_key "scores", "users", column: "last_updated_by_id"
  add_foreign_key "series", "courses"
  add_foreign_key "series_memberships", "activities"
  add_foreign_key "series_memberships", "series"
  add_foreign_key "submissions", "activities", column: "exercise_id"
  add_foreign_key "submissions", "courses"
  add_foreign_key "submissions", "users"
  add_foreign_key "users", "institutions"
end
