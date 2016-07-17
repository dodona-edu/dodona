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

ActiveRecord::Schema.define(version: 20160717140546) do

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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "exercises", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name_nl"
    t.string   "name_en"
    t.integer  "visibility",    default: 0
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "path"
    t.integer  "repository_id"
    t.integer  "judge_id"
    t.index ["judge_id"], name: "index_exercises_on_judge_id", using: :btree
    t.index ["name_nl"], name: "index_exercises_on_name_nl", using: :btree
    t.index ["repository_id"], name: "index_exercises_on_repository_id", using: :btree
  end

  create_table "judges", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "image"
    t.string   "path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "submissions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "exercise_id"
    t.integer  "user_id"
    t.text     "code",        limit: 65535
    t.text     "result",      limit: 65535
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "status"
    t.index ["exercise_id"], name: "index_submissions_on_exercise_id", using: :btree
    t.index ["user_id"], name: "index_submissions_on_user_id", using: :btree
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "username"
    t.string   "ugent_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.integer  "permission", default: 0
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["username"], name: "index_users_on_username", using: :btree
  end

  add_foreign_key "exercises", "judges"
  add_foreign_key "exercises", "repositories"
  add_foreign_key "repositories", "judges"
  add_foreign_key "submissions", "exercises"
  add_foreign_key "submissions", "users"
end
