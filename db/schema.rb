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

ActiveRecord::Schema.define(version: 2020_03_26_010625) do

  create_table "druid_retrieval_attempts", force: :cascade do |t|
    t.integer "druid_id"
    t.integer "response_status"
    t.string "response_reason_phrase"
    t.string "output_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["druid_id"], name: "index_druid_retrieval_attempts_on_druid_id"
  end

  create_table "druids", force: :cascade do |t|
    t.string "druid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["druid"], name: "index_druids_on_druid", unique: true
  end

end
