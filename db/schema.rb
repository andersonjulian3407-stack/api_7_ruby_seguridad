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

ActiveRecord::Schema[8.1].define(version: 2026_06_02_200000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "direccion", null: false
    t.datetime "fecha_creacion", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "nombre", null: false
    t.string "telefono", null: false
    t.datetime "updated_at", null: false
  end

  create_table "employees", force: :cascade do |t|
    t.string "apellido", null: false
    t.string "cargo", null: false
    t.bigint "company_id", null: false
    t.string "correo", null: false
    t.datetime "created_at", null: false
    t.string "nombre", null: false
    t.decimal "salario", precision: 12, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_employees_on_company_id"
    t.index ["correo"], name: "index_employees_on_correo", unique: true
  end

  create_table "role_claims", force: :cascade do |t|
    t.string "claim_type", null: false
    t.string "claim_value", null: false
    t.bigint "role_id", null: false
    t.index ["role_id"], name: "index_role_claims_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nombre", null: false
    t.datetime "updated_at", null: false
    t.index ["nombre"], name: "index_roles_on_nombre", unique: true
  end

  create_table "user_claims", force: :cascade do |t|
    t.string "claim_type", null: false
    t.string "claim_value", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_claims_on_user_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "company_id"
    t.string "contrasena_hash", null: false
    t.string "correo", null: false
    t.datetime "created_at", null: false
    t.datetime "fecha_creacion", default: -> { "now()" }, null: false
    t.string "nombre", null: false
    t.datetime "updated_at", null: false
    t.index ["correo"], name: "index_users_on_correo", unique: true
  end

  add_foreign_key "employees", "companies"
  add_foreign_key "role_claims", "roles", on_delete: :cascade
  add_foreign_key "user_claims", "users", on_delete: :cascade
  add_foreign_key "user_roles", "roles", on_delete: :cascade
  add_foreign_key "user_roles", "users", on_delete: :cascade
  add_foreign_key "users", "companies", on_delete: :nullify
end
