# ONION: Capa de Dominio — Claims directos del usuario (estilo ASP.NET Identity)
class UserClaim < ApplicationRecord
  self.ignored_columns += %w[created_at updated_at]

  belongs_to :user

  validates :claim_type,  presence: true
  validates :claim_value, presence: true
end
