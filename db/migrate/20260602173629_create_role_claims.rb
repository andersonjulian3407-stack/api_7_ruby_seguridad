class CreateRoleClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :role_claims do |t|
      t.references :role, null: false, foreign_key: { on_delete: :cascade }
      t.string :claim_type, null: false
      t.string :claim_value, null: false

      t.timestamps
    end
  end
end
