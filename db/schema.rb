# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_04_24_161936) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "activities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name_nl"
    t.string "name_en"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.index ["judge_id"], name: "index_activities_on_judge_id"
    t.index ["name_nl"], name: "index_activities_on_name_nl"
    t.index ["path", "repository_id"], name: "index_activities_on_path_and_repository_id", unique: true
    t.index ["programming_language_id"], name: "fk_rails_f60feebafd"
    t.index ["repository_id"], name: "index_activities_on_repository_id"
    t.index ["repository_token"], name: "index_activities_on_repository_token", unique: true
    t.index ["status"], name: "index_activities_on_status"
  end

  create_table "activity_labels", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.bigint "label_id", null: false
    t.index ["activity_id", "label_id"], name: "index_activity_labels_on_activity_id_and_label_id", unique: true
    t.index ["label_id"], name: "fk_rails_0510a660e5"
  end

  create_table "activity_read_states", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "activity_id", null: false
    t.integer "course_id"
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["activity_id", "course_id", "user_id"], name: "activity_read_states_unique", unique: true
    t.index ["course_id"], name: "fk_rails_f674cacc14"
    t.index ["user_id"], name: "fk_rails_96d00253e9"
  end

  create_table "activity_statuses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.boolean "accepted", default: false, null: false
    t.boolean "accepted_before_deadline", default: false, null: false
    t.boolean "solved", default: false, null: false
    t.boolean "started", default: false, null: false
    t.datetime "solved_at"
    t.integer "activity_id", null: false
    t.integer "series_id"
    t.integer "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["activity_id", "series_id", "user_id"], name: "index_activity_statuses_on_activity_id_and_series_id_and_user_id", unique: true
    t.index ["series_id"], name: "fk_rails_1bc42c2178"
    t.index ["user_id"], name: "fk_rails_8a05a160e8"
  end

  create_table "annotations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "line_nr"
    t.integer "submission_id"
    t.integer "user_id"
    t.text "annotation_text"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["submission_id"], name: "index_annotations_on_submission_id"
    t.index ["user_id"], name: "index_annotations_on_user_id"
  end

  create_table "api_tokens", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.string "token_digest"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest"
    t.index ["user_id", "description"], name: "index_api_tokens_on_user_id_and_description", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "course_labels", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "course_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "name"], name: "index_course_labels_on_course_id_and_name", unique: true
  end

  create_table "course_membership_labels", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "course_membership_id", null: false
    t.bigint "course_label_id", null: false
    t.index ["course_label_id", "course_membership_id"], name: "unique_label_and_course_membership_index", unique: true
    t.index ["course_membership_id"], name: "fk_rails_7d6a6611cf"
  end

  create_table "course_memberships", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "course_id"
    t.integer "user_id"
    t.integer "status", default: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "favorite", default: false
    t.index ["course_id"], name: "index_course_memberships_on_course_id"
    t.index ["user_id", "course_id"], name: "index_course_memberships_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_course_memberships_on_user_id"
  end

  create_table "course_repositories", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "course_id", null: false
    t.integer "repository_id", null: false
    t.index ["course_id", "repository_id"], name: "index_course_repositories_on_course_id_and_repository_id", unique: true
    t.index ["repository_id"], name: "fk_rails_4d1393e517"
  end

  create_table "courses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "year"
    t.string "secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.integer "visibility"
    t.integer "registration"
    t.integer "color"
    t.string "teacher", default: ""
    t.bigint "institution_id"
    t.string "search", limit: 4096
    t.boolean "moderated", default: false, null: false
    t.index ["institution_id"], name: "index_courses_on_institution_id"
  end

  create_table "delayed_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "events", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "event_type", null: false
    t.integer "user_id"
    t.string "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type"], name: "index_events_on_event_type"
    t.index ["user_id"], name: "fk_rails_0cb5590091"
  end

  create_table "exports", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_exports_on_user_id"
  end

  create_table "institutions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.string "logo"
    t.string "sso_url"
    t.string "slo_url"
    t.text "certificate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "entity_id"
    t.integer "provider"
    t.string "identifier"
    t.index ["identifier"], name: "index_institutions_on_identifier", unique: true
  end

  create_table "judges", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "image"
    t.string "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "renderer", null: false
    t.string "remote"
    t.index ["name"], name: "index_judges_on_name", unique: true
  end

  create_table "labels", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.integer "color", null: false
    t.index ["name"], name: "index_labels_on_name", unique: true
  end

  create_table "notifications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "message", null: false
    t.boolean "read", default: false, null: false
    t.integer "user_id", null: false
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "programming_languages", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "editor_name", null: false
    t.string "extension", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_programming_languages_on_name", unique: true
  end

  create_table "repositories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "remote"
    t.string "path"
    t.integer "judge_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["judge_id"], name: "index_repositories_on_judge_id"
    t.index ["name"], name: "index_repositories_on_name", unique: true
    t.index ["path"], name: "index_repositories_on_path", unique: true
  end

  create_table "repository_admins", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "repository_id", null: false
    t.integer "user_id", null: false
    t.index ["repository_id", "user_id"], name: "index_repository_admins_on_repository_id_and_user_id", unique: true
    t.index ["user_id"], name: "fk_rails_6b59ad362c"
  end

  create_table "series", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "course_id"
    t.string "name"
    t.text "description"
    t.integer "visibility"
    t.integer "order", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deadline"
    t.string "access_token"
    t.string "indianio_token"
    t.boolean "progress_enabled", default: true, null: false
    t.boolean "activities_visible", default: true, null: false
    t.index ["access_token"], name: "index_series_on_access_token"
    t.index ["course_id"], name: "index_series_on_course_id"
    t.index ["deadline"], name: "index_series_on_deadline"
    t.index ["indianio_token"], name: "index_series_on_indianio_token"
    t.index ["name"], name: "index_series_on_name"
    t.index ["visibility"], name: "index_series_on_visibility"
  end

  create_table "series_memberships", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "series_id"
    t.integer "activity_id"
    t.integer "order", default: 999
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_series_memberships_on_activity_id"
    t.index ["series_id", "activity_id"], name: "index_series_memberships_on_series_id_and_activity_id", unique: true
    t.index ["series_id"], name: "index_series_memberships_on_series_id"
  end

  create_table "submissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "exercise_id"
    t.integer "user_id"
    t.string "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.boolean "accepted", default: false
    t.integer "course_id"
    t.string "fs_key", limit: 24
    t.index ["accepted"], name: "index_submissions_on_accepted"
    t.index ["course_id"], name: "index_submissions_on_course_id"
    t.index ["exercise_id", "user_id", "accepted", "created_at"], name: "ex_us_ac_cr_index"
    t.index ["exercise_id", "user_id", "status", "created_at"], name: "ex_us_st_cr_index"
    t.index ["exercise_id"], name: "index_submissions_on_exercise_id"
    t.index ["fs_key"], name: "index_submissions_on_fs_key", unique: true
    t.index ["status"], name: "index_submissions_on_status"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "username"
    t.string "first_name"
    t.string "last_name"
    t.string "email"
    t.integer "permission", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "lang", default: "nl"
    t.string "token"
    t.string "time_zone", default: "Brussels"
    t.bigint "institution_id"
    t.string "search", limit: 4096
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["institution_id"], name: "index_users_on_institution_id"
    t.index ["token"], name: "index_users_on_token"
    t.index ["username", "institution_id"], name: "index_users_on_username_and_institution_id", unique: true
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
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
  add_foreign_key "annotations", "submissions"
  add_foreign_key "annotations", "users"
  add_foreign_key "course_labels", "courses", on_delete: :cascade
  add_foreign_key "course_membership_labels", "course_labels", on_delete: :cascade
  add_foreign_key "course_membership_labels", "course_memberships", on_delete: :cascade
  add_foreign_key "course_repositories", "courses"
  add_foreign_key "course_repositories", "repositories"
  add_foreign_key "courses", "institutions"
  add_foreign_key "events", "users", on_delete: :cascade
  add_foreign_key "exports", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "repositories", "judges"
  add_foreign_key "repository_admins", "repositories"
  add_foreign_key "repository_admins", "users"
  add_foreign_key "series", "courses"
  add_foreign_key "series_memberships", "activities"
  add_foreign_key "series_memberships", "series"
  add_foreign_key "submissions", "activities", column: "exercise_id"
  add_foreign_key "submissions", "courses"
  add_foreign_key "submissions", "users"
  add_foreign_key "users", "institutions"
end
