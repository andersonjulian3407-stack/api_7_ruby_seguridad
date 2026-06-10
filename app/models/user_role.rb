# ONION: Capa de Dominio — Tabla join entre User y Role (estilo ASP.NET Identity)
class UserRole < ApplicationRecord
  self.ignored_columns += %w[created_at updated_at]

  belongs_to :user
  belongs_to :role

  validates :user_id, uniqueness: { scope: :role_id, message: "ya tiene este rol asignado" }
end
