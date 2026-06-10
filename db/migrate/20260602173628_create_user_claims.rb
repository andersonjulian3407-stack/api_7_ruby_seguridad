class CreateUserClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :user_claims do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :claim_type, null: false
      t.string :claim_value, null: false

      t.timestamps
    end
  end
end
