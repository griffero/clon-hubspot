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

ActiveRecord::Schema[8.0].define(version: 2026_03_03_130510) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.string "hubspot_id"
    t.string "name"
    t.string "domain"
    t.string "industry"
    t.string "phone"
    t.string "city"
    t.string "country"
    t.integer "number_of_employees"
    t.decimal "annual_revenue"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_companies_on_domain"
    t.index ["hubspot_id"], name: "index_companies_on_hubspot_id", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.string "hubspot_id"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.string "company_name"
    t.string "job_title"
    t.string "lifecycle_stage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_contacts_on_email"
    t.index ["hubspot_id"], name: "index_contacts_on_hubspot_id", unique: true
  end

  create_table "deals", force: :cascade do |t|
    t.string "hubspot_id"
    t.string "name"
    t.decimal "amount"
    t.date "close_date"
    t.bigint "stage_id", null: false
    t.bigint "pipeline_id", null: false
    t.string "hubspot_owner_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hubspot_id"], name: "index_deals_on_hubspot_id", unique: true
    t.index ["pipeline_id"], name: "index_deals_on_pipeline_id"
    t.index ["stage_id"], name: "index_deals_on_stage_id"
  end

  create_table "export_checkpoints", force: :cascade do |t|
    t.bigint "export_run_id", null: false
    t.string "portal_id", null: false
    t.string "extractor_key", null: false
    t.integer "status", default: 0, null: false
    t.string "cursor"
    t.datetime "high_watermark"
    t.integer "records_exported", default: 0, null: false
    t.integer "retries", default: 0, null: false
    t.datetime "last_synced_at"
    t.text "last_error"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["export_run_id", "portal_id", "extractor_key"], name: "idx_export_checkpoints_run_portal_key", unique: true
    t.index ["export_run_id"], name: "index_export_checkpoints_on_export_run_id"
    t.index ["status"], name: "index_export_checkpoints_on_status"
  end

  create_table "export_runs", force: :cascade do |t|
    t.string "run_id", null: false
    t.string "portal_id", null: false
    t.string "mode", default: "full", null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "last_heartbeat_at"
    t.integer "retry_count", default: 0, null: false
    t.integer "total_records", default: 0, null: false
    t.jsonb "stats", default: {}, null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["portal_id", "created_at"], name: "index_export_runs_on_portal_id_and_created_at"
    t.index ["run_id"], name: "index_export_runs_on_run_id", unique: true
    t.index ["status"], name: "index_export_runs_on_status"
  end

  create_table "export_tables", force: :cascade do |t|
    t.bigint "export_run_id", null: false
    t.string "extractor_key", null: false
    t.string "object_type", null: false
    t.string "file_path", null: false
    t.integer "expected_count"
    t.integer "extracted_count", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.string "checksum"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["export_run_id", "extractor_key"], name: "index_export_tables_on_export_run_id_and_extractor_key", unique: true
    t.index ["export_run_id"], name: "index_export_tables_on_export_run_id"
    t.index ["status"], name: "index_export_tables_on_status"
  end

  create_table "hubspot_associations", force: :cascade do |t|
    t.string "from_object_type"
    t.string "from_hubspot_id"
    t.string "to_object_type"
    t.string "to_hubspot_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_object_type", "from_hubspot_id", "to_object_type", "to_hubspot_id"], name: "index_hubspot_associations_uniqueness", unique: true
    t.index ["to_object_type", "to_hubspot_id"], name: "index_hubspot_associations_on_to_object_type_and_to_hubspot_id"
  end

  create_table "magic_link_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_magic_link_tokens_on_expires_at"
    t.index ["token_digest"], name: "index_magic_link_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_magic_link_tokens_on_user_id"
  end

  create_table "pipelines", force: :cascade do |t|
    t.string "hubspot_id"
    t.string "label"
    t.integer "display_order"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hubspot_id"], name: "index_pipelines_on_hubspot_id", unique: true
  end

  create_table "stages", force: :cascade do |t|
    t.string "hubspot_id"
    t.bigint "pipeline_id", null: false
    t.string "label"
    t.integer "display_order"
    t.decimal "probability"
    t.boolean "is_closed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hubspot_id"], name: "index_stages_on_hubspot_id", unique: true
    t.index ["pipeline_id"], name: "index_stages_on_pipeline_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "deals", "pipelines"
  add_foreign_key "deals", "stages"
  add_foreign_key "export_checkpoints", "export_runs"
  add_foreign_key "export_tables", "export_runs"
  add_foreign_key "magic_link_tokens", "users"
  add_foreign_key "stages", "pipelines"
end
