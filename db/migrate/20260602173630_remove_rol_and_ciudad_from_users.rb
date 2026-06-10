class RemoveRolAndCiudadFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :rol, :string, default: "USUARIO", null: false
    remove_column :users, :ciudad, :string
  end
end
