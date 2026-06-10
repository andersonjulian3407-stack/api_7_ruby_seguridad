# ONION: Capa de Dominio — Entidad Usuario
# Módulo 5: Seguridad con JWT
# Módulo 6: Modelo Identity — roles y claims relacionales (estilo ASP.NET Identity)
class User < ApplicationRecord
  # has_secure_password usa bcrypt para hashear la contraseña automáticamente.
  # Provee: password= (hashea con bcrypt) y authenticate(plain) -> User | false
  has_secure_password validations: false

  # Rails busca password_digest por defecto; lo remapeamos a nuestra columna:
  alias_attribute :password_digest, :contrasena_hash

  # ── Relaciones ────────────────────────────────────────────────────────────
  belongs_to :company, optional: true

  has_many :user_roles,  dependent: :destroy
  has_many :roles,       through: :user_roles
  has_many :user_claims, dependent: :destroy

  # ── Validaciones ──────────────────────────────────────────────────────────
  validates :nombre, presence: true
  validates :correo, presence: true, uniqueness: true,
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, if: :password_required?

  # ── Métodos de consulta de roles ─────────────────────────────────────────

  def has_role?(role_name)
    roles.exists?(nombre: role_name)
  end

  def admin?
    has_role?("ADMIN")
  end

  def role_names
    roles.pluck(:nombre)
  end

  # ── Métodos de consulta de claims ────────────────────────────────────────

  # Consolida claims propios del usuario + claims heredados de todos sus roles.
  # Retorna un array de pares [claim_type, claim_value] sin duplicados.
  def all_claims
    direct    = user_claims.pluck(:claim_type, :claim_value)
    from_roles = RoleClaim.where(role_id: role_ids).pluck(:claim_type, :claim_value)
    (direct + from_roles).uniq
  end

  # Verifica si el usuario posee un claim específico (directo o heredado de rol)
  def has_claim?(type, value)
    all_claims.include?([type, value])
  end

  # Devuelve los claims como hash { claim_type => claim_value }
  # Si hay múltiples valores para el mismo tipo, el último gana (igual que ASP.NET)
  def claims_hash
    all_claims.to_h
  end

  private

  def password_required?
    new_record? || password.present?
  end
end
