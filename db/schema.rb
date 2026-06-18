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

ActiveRecord::Schema[8.1].define(version: 2026_06_18_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "accountants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.uuid "firm_id", null: false
    t.boolean "is_active", default: true, null: false
    t.string "name"
    t.string "password_digest"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["firm_id", "email"], name: "index_accountants_on_firm_id_and_email", unique: true
    t.index ["firm_id"], name: "index_accountants_on_firm_id"
  end

  create_table "client_summaries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.json "actors"
    t.uuid "client_id", null: false
    t.json "concluded_discussions"
    t.datetime "created_at", null: false
    t.integer "emails_analyzed_count", null: false
    t.datetime "last_refreshed_at", null: false
    t.json "open_action_items"
    t.text "summary_encrypted", null: false
    t.integer "threads_analyzed_count", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_summaries_on_client_id", unique: true
  end

  create_table "clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.uuid "firm_id", null: false
    t.string "name"
    t.string "phone"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["firm_id", "email"], name: "index_clients_on_firm_id_and_email", unique: true
    t.index ["firm_id"], name: "index_clients_on_firm_id"
  end

  create_table "email_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "accountant_id"
    t.text "body"
    t.text "cc_emails"
    t.datetime "created_at", null: false
    t.string "from_email", null: false
    t.string "graph_message_id", null: false
    t.string "message_id", null: false
    t.datetime "received_at"
    t.datetime "sent_at", null: false
    t.string "subject"
    t.uuid "thread_id", null: false
    t.text "to_emails"
    t.datetime "updated_at", null: false
    t.index ["accountant_id"], name: "index_email_messages_on_accountant_id"
    t.index ["graph_message_id"], name: "index_email_messages_on_graph_message_id", unique: true
    t.index ["message_id"], name: "index_email_messages_on_message_id", unique: true
    t.index ["thread_id", "sent_at"], name: "index_email_messages_on_thread_id_and_sent_at"
    t.index ["thread_id"], name: "index_email_messages_on_thread_id"
  end

  create_table "email_summaries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.json "actors"
    t.json "concluded_discussions"
    t.datetime "created_at", null: false
    t.integer "emails_analyzed_count", null: false
    t.datetime "last_refreshed_at", null: false
    t.json "open_action_items"
    t.text "summary_encrypted", null: false
    t.uuid "thread_id", null: false
    t.datetime "updated_at", null: false
    t.index ["thread_id"], name: "index_email_summaries_on_thread_id", unique: true
  end

  create_table "email_threads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.string "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["client_id", "conversation_id"], name: "index_email_threads_on_client_id_and_conversation_id", unique: true
    t.index ["client_id"], name: "index_email_threads_on_client_id"
  end

  create_table "firms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "domain"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_firms_on_domain", unique: true
  end

  add_foreign_key "accountants", "firms"
  add_foreign_key "client_summaries", "clients"
  add_foreign_key "clients", "firms"
  add_foreign_key "email_messages", "accountants"
  add_foreign_key "email_messages", "email_threads", column: "thread_id"
  add_foreign_key "email_summaries", "email_threads", column: "thread_id"
  add_foreign_key "email_threads", "clients"
end
