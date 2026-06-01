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

ActiveRecord::Schema[8.1].define(version: 2026_05_30_000001) do
  create_table "companies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "direccion", null: false
    t.datetime "fecha_creacion", default: -> { "getdate()" }, null: false
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

  create_table "sysdiagrams", primary_key: "diagram_id", id: :integer, force: :cascade do |t|
    t.binary "definition"
    t.string "name", null: false
    t.integer "principal_id", null: false
    t.integer "version"
    t.index ["principal_id", "name"], name: "UK_principal_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "company_id"
    t.string "contrasena_hash", null: false
    t.string "correo", null: false
    t.datetime "created_at", null: false
    t.datetime "fecha_creacion", default: -> { "getdate()" }, null: false
    t.string "nombre", null: false
    t.string "rol", default: "USUARIO", null: false
    t.datetime "updated_at", null: false
    t.index ["correo"], name: "index_users_on_correo", unique: true
  end

  add_foreign_key "employees", "companies"
  add_foreign_key "users", "companies", on_delete: :nullify
end
