# ONION: Capa de Dominio — Entidad Usuario
# Módulo 5: Seguridad con JWT
# has_secure_password usa bcrypt para hashear la contraseña automáticamente
class User < ApplicationRecord
  # Activa has_secure_password que provee:
  #   - password= (hashea con bcrypt y guarda en contrasena_hash)
  #   - authenticate(plain_password) -> User | false
  has_secure_password validations: false

  # Usar la columna contrasena_hash como campo de digest para has_secure_password
  # Rails busca password_digest por defecto; lo remapeamos:
  alias_attribute :password_digest, :contrasena_hash

  belongs_to :company, optional: true

  ROLES = %w[ADMIN USUARIO].freeze

  validates :nombre,  presence: true
  validates :correo,  presence: true, uniqueness: true,
                      format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :rol,     inclusion: { in: ROLES, message: "debe ser ADMIN o USUARIO" }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  def admin?
    rol == "ADMIN"
  end

  private

  def password_required?
    new_record? || password.present?
  end
end
