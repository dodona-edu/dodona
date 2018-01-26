# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180126085937) do

  create_table "course_memberships", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "course_id"
    t.integer "user_id"
    t.integer "status", default: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_memberships_on_course_id"
    t.index ["user_id"], name: "index_course_memberships_on_user_id"
  end

  create_table "courses", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "year"
    t.string "secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.integer "visibility", default: 0
    t.integer "registration", default: 0
    t.integer "correct_solutions"
    t.integer "color"
    t.string "teacher", default: ""
  end

  create_table "delayed_jobs", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
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

  create_table "exercises", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name_nl"
    t.string "name_en"
    t.integer "visibility", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "path"
    t.string "description_format"
    t.string "programming_language"
    t.integer "repository_id"
    t.integer "judge_id"
    t.integer "status", default: 0
    t.index ["judge_id"], name: "index_exercises_on_judge_id"
    t.index ["name_nl"], name: "index_exercises_on_name_nl"
    t.index ["path", "repository_id"], name: "index_exercises_on_path_and_repository_id", unique: true
    t.index ["programming_language"], name: "index_exercises_on_programming_language"
    t.index ["repository_id"], name: "index_exercises_on_repository_id"
    t.index ["status"], name: "index_exercises_on_status"
    t.index ["visibility"], name: "index_exercises_on_visibility"
  end

  create_table "institutions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "short_name"
    t.string "logo"
    t.string "sso_url"
    t.string "slo_url"
    t.text "certificate"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "entity_id"
  end

  create_table "judges", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "image"
    t.string "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "renderer", null: false
    t.string "runner", null: false
    t.string "remote"
    t.index ["name"], name: "index_judges_on_name", unique: true
  end

  create_table "repositories", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "name"
    t.string "remote"
    t.string "path"
    t.integer "judge_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["judge_id"], name: "index_repositories_on_judge_id"
    t.index ["path"], name: "index_repositories_on_path", unique: true
  end

  create_table "series", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "course_id"
    t.string "name"
    t.text "description"
    t.integer "visibility"
    t.integer "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deadline"
    t.string "access_token"
    t.string "indianio_token"
    t.index ["access_token"], name: "index_series_on_access_token"
    t.index ["course_id"], name: "index_series_on_course_id"
    t.index ["deadline"], name: "index_series_on_deadline"
    t.index ["indianio_token"], name: "index_series_on_indianio_token"
    t.index ["name"], name: "index_series_on_name"
    t.index ["visibility"], name: "index_series_on_visibility"
  end

  create_table "series_memberships", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "series_id"
    t.integer "exercise_id"
    t.integer "order", default: 999
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "users_correct"
    t.integer "users_attempted"
    t.index ["exercise_id"], name: "index_series_memberships_on_exercise_id"
    t.index ["series_id", "exercise_id"], name: "index_series_memberships_on_series_id_and_exercise_id"
    t.index ["series_id"], name: "index_series_memberships_on_series_id"
  end

  create_table "submission_details", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.text "code"
    t.binary "result", limit: 16777215
  end

  create_table "submissions", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "exercise_id"
    t.integer "user_id"
    t.string "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status"
    t.boolean "accepted", default: false
    t.integer "course_id"
    t.index ["accepted"], name: "index_submissions_on_accepted"
    t.index ["course_id"], name: "index_submissions_on_course_id"
    t.index ["exercise_id", "user_id", "accepted", "created_at"], name: "ex_us_ac_cr_index"
    t.index ["exercise_id", "user_id", "status", "created_at"], name: "ex_us_st_cr_index"
    t.index ["exercise_id"], name: "index_submissions_on_exercise_id"
    t.index ["status"], name: "index_submissions_on_status"
    t.index ["user_id"], name: "index_submissions_on_user_id"
  end

  create_table "users", id: :integer, force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "username"
    t.string "ugent_id"
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
    t.index ["institution_id"], name: "index_users_on_institution_id"
    t.index ["token"], name: "index_users_on_token"
    t.index ["username"], name: "index_users_on_username"
  end

  add_foreign_key "exercises", "judges"
  add_foreign_key "exercises", "repositories"
  add_foreign_key "repositories", "judges"
  add_foreign_key "series", "courses"
  add_foreign_key "series_memberships", "exercises"
  add_foreign_key "series_memberships", "series"
  add_foreign_key "submissions", "courses"
  add_foreign_key "submissions", "exercises"
  add_foreign_key "submissions", "users"
  add_foreign_key "users", "institutions"
end
