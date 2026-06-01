class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string  :nombre,          null: false
      t.string  :correo,          null: false
      t.string  :contrasena_hash, null: false
      t.string  :rol,             null: false, default: "USUARIO"  # ADMIN | USUARIO
      t.bigint  :company_id                                          # opcional — para políticas
      t.datetime :fecha_creacion, null: false, default: -> { "getdate()" }

      t.timestamps
    end

    add_index :users, :correo, unique: true
    add_foreign_key :users, :companies, column: :company_id, on_delete: :nullify
  end
end
