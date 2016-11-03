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

ActiveRecord::Schema.define(version: 20161103103942) do

  create_table "course_memberships", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "course_id"
    t.integer  "user_id"
    t.integer  "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_course_memberships_on_course_id", using: :btree
    t.index ["user_id"], name: "index_course_memberships_on_user_id", using: :btree
  end

  create_table "courses", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "year"
    t.string   "secret"
    t.boolean  "open"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.text     "description", limit: 65535
  end

  create_table "delayed_jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "priority",                 default: 0, null: false
    t.integer  "attempts",                 default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  end

  create_table "exercises", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name_nl"
    t.string   "name_en"
    t.integer  "visibility",           default: 0
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "path"
    t.string   "description_format"
    t.string   "programming_language"
    t.integer  "repository_id"
    t.integer  "judge_id"
    t.integer  "status",               default: 0
    t.index ["judge_id"], name: "index_exercises_on_judge_id", using: :btree
    t.index ["name_nl"], name: "index_exercises_on_name_nl", using: :btree
    t.index ["path", "repository_id"], name: "index_exercises_on_path_and_repository_id", unique: true, using: :btree
    t.index ["programming_language"], name: "index_exercises_on_programming_language", using: :btree
    t.index ["repository_id"], name: "index_exercises_on_repository_id", using: :btree
    t.index ["status"], name: "index_exercises_on_status", using: :btree
    t.index ["visibility"], name: "index_exercises_on_visibility", using: :btree
  end

  create_table "judges", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "image"
    t.string   "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string   "renderer",   null: false
    t.string   "runner",     null: false
    t.string   "remote"
    t.index ["name"], name: "index_judges_on_name", unique: true, using: :btree
  end

  create_table "repositories", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "remote"
    t.string   "path"
    t.integer  "judge_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["judge_id"], name: "index_repositories_on_judge_id", using: :btree
    t.index ["path"], name: "index_repositories_on_path", unique: true, using: :btree
  end

  create_table "series", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "course_id"
    t.string   "name"
    t.text     "description", limit: 65535
    t.integer  "visibility"
    t.integer  "order"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.datetime "deadline"
    t.string   "token"
    t.index ["course_id"], name: "index_series_on_course_id", using: :btree
    t.index ["deadline"], name: "index_series_on_deadline", using: :btree
    t.index ["name"], name: "index_series_on_name", using: :btree
    t.index ["token"], name: "index_series_on_token", using: :btree
    t.index ["visibility"], name: "index_series_on_visibility", using: :btree
  end

  create_table "series_memberships", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "series_id"
    t.integer  "exercise_id"
    t.integer  "order",           default: 999
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "users_correct"
    t.integer  "users_attempted"
    t.index ["exercise_id"], name: "index_series_memberships_on_exercise_id", using: :btree
    t.index ["series_id"], name: "index_series_memberships_on_series_id", using: :btree
  end

  create_table "submissions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "exercise_id"
    t.integer  "user_id"
    t.text     "code",        limit: 65535
    t.string   "summary"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.integer  "status"
    t.binary   "result",      limit: 16777215
    t.boolean  "accepted",                     default: false
    t.index ["accepted"], name: "index_submissions_on_accepted", using: :btree
    t.index ["exercise_id", "user_id", "accepted", "created_at"], name: "ex_us_ac_cr_index", using: :btree
    t.index ["exercise_id"], name: "index_submissions_on_exercise_id", using: :btree
    t.index ["status"], name: "index_submissions_on_status", using: :btree
    t.index ["user_id"], name: "index_submissions_on_user_id", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "username"
    t.string   "ugent_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.integer  "permission", default: 0
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "lang",       default: "nl"
    t.string   "token"
    t.index ["token"], name: "index_users_on_token", using: :btree
    t.index ["username"], name: "index_users_on_username", using: :btree
  end

  add_foreign_key "exercises", "judges"
  add_foreign_key "exercises", "repositories"
  add_foreign_key "repositories", "judges"
  add_foreign_key "series", "courses"
  add_foreign_key "series_memberships", "exercises"
  add_foreign_key "series_memberships", "series"
  add_foreign_key "submissions", "exercises"
  add_foreign_key "submissions", "users"
end
