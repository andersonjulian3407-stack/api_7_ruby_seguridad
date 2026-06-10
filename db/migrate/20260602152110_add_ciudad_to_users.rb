class AddCiudadToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :ciudad, :string
  end
end
