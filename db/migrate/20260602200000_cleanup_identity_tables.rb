class CleanupIdentityTables < ActiveRecord::Migration[8.1]
  def up
    remove_column :user_roles,  :created_at
    remove_column :user_roles,  :updated_at
    remove_column :user_claims, :created_at
    remove_column :user_claims, :updated_at
    remove_column :role_claims, :created_at
    remove_column :role_claims, :updated_at
    remove_index  :roles, :nombre
    change_column_null :roles, :nombre, false
    add_index :roles, :nombre, unique: true
  end

  def down
    add_column :user_roles,  :created_at, :datetime, null: false, default: -> { "NOW()" }
    add_column :user_roles,  :updated_at, :datetime, null: false, default: -> { "NOW()" }
    add_column :user_claims, :created_at, :datetime, null: false, default: -> { "NOW()" }
    add_column :user_claims, :updated_at, :datetime, null: false, default: -> { "NOW()" }
    add_column :role_claims, :created_at, :datetime, null: false, default: -> { "NOW()" }
    add_column :role_claims, :updated_at, :datetime, null: false, default: -> { "NOW()" }
    remove_index :roles, :nombre
    change_column_null :roles, :nombre, true
    add_index :roles, :nombre, unique: true
  end
end
