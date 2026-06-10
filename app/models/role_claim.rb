# ONION: Capa de Dominio — Claims asociados a un rol (estilo ASP.NET Identity)
# Todos los usuarios con ese rol heredan automáticamente estos claims
class RoleClaim < ApplicationRecord
  self.ignored_columns += %w[created_at updated_at]

  belongs_to :role

  validates :claim_type,  presence: true
  validates :claim_value, presence: true
end
