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

ActiveRecord::Schema[8.1].define(version: 2026_05_30_124118) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "line_items", force: :cascade do |t|
    t.integer "amount_cents"
    t.integer "amount_cents_monthly"
    t.integer "billing_period"
    t.integer "category"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "payment_method"
    t.bigint "property_id"
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_line_items_on_property_id"
  end

  create_table "properties", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "ownership_percentage"
    t.datetime "updated_at", null: false
  end

  create_table "property_expenses", force: :cascade do |t|
    t.integer "amount_cents"
    t.integer "amount_cents_monthly"
    t.integer "billing_period"
    t.integer "category"
    t.datetime "created_at", null: false
    t.string "name"
    t.bigint "property_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_property_expenses_on_property_id"
  end

  create_table "spending_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "monthly_target_cents"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "weekly_target_cents"
    t.index ["name"], name: "index_spending_categories_on_name", unique: true
  end

  create_table "spending_entries", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "spending_category_id", null: false
    t.date "spent_on", null: false
    t.datetime "updated_at", null: false
    t.index ["spending_category_id", "spent_on"], name: "index_spending_entries_on_spending_category_id_and_spent_on"
    t.index ["spending_category_id"], name: "index_spending_entries_on_spending_category_id"
    t.index ["spent_on"], name: "index_spending_entries_on_spent_on"
  end

  add_foreign_key "line_items", "properties"
  add_foreign_key "property_expenses", "properties"
  add_foreign_key "spending_entries", "spending_categories"
end
