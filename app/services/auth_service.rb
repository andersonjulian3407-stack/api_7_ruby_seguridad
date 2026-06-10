# ONION: Capa de Aplicación — Servicio de autenticación
# Módulo 5: JWT — registro, login, emisión y verificación de tokens
# Módulo 6: Modelo Identity — roles y claims relacionales
require "jwt"
require "bcrypt"

class AuthService
  SECRET_KEY  = ENV.fetch("JWT_SECRET_KEY") { Rails.application.secret_key_base }
  TOKEN_EXPIRY = 24 * 60 * 60  # 24 horas en segundos

  # Registro: crea usuario, asigna roles y claims opcionales.
  #
  # Parámetros:
  #   roles:  Array de nombres de rol (ej: ["ADMIN", "USUARIO"]). Default: ["USUARIO"]
  #   claims: Array de hashes con :tipo y :valor (ej: [{tipo: "ciudad", valor: "Bogota"}])
  def register(nombre:, correo:, password:, roles: ["USUARIO"], company_id: nil, claims: [])
    Rails.logger.info("[AuthService] Registrando usuario: #{correo}")

    if User.exists?(correo: correo)
      raise ValidationError.new(["El correo #{correo} ya está registrado"])
    end

    role_names = Array(roles).map { |role| role.to_s.strip.upcase }.reject(&:blank?)
    role_names = ["USUARIO"] if role_names.empty?
    role_records = role_names.uniq.map { |name| Role.find_or_create_by!(nombre: name) }

    user = nil

    User.transaction do
      user = User.new(
        nombre:     nombre,
        correo:     correo,
        password:   password,
        company_id: company_id
      )

      unless user.save
        raise ValidationError.new(user.errors.full_messages)
      end

      # Asignar roles via tabla user_roles
      user.roles << role_records

      # Asignar claims directos del usuario
      Array(claims).each do |claim|
        user.user_claims.create!(
          claim_type:  claim[:tipo]  || claim["tipo"],
          claim_value: claim[:valor] || claim["valor"]
        )
      end
    end

    Rails.logger.info("[AuthService] Usuario registrado con ID: #{user.id}, roles: #{role_names}")

    {
      id:         user.id,
      nombre:     user.nombre,
      correo:     user.correo,
      roles:      user.role_names,
      claims:     user.claims_hash,
      company_id: user.company_id
    }
  end

  # Login: valida credenciales y emite JWT firmado con HS256
  def login(correo:, password:)
    Rails.logger.info("[AuthService] Intento de login: #{correo}")
    user = User.find_by(correo: correo)

    unless user&.authenticate(password)
      raise AuthenticationError, "Credenciales inválidas"
    end

    token = issue_token(user)
    Rails.logger.info("[AuthService] Login exitoso para usuario ID: #{user.id}")

    {
      token:     token,
      tipo:      "Bearer",
      expira_en: TOKEN_EXPIRY,
      usuario: {
        id:         user.id,
        nombre:     user.nombre,
        correo:     user.correo,
        roles:      user.role_names,
        claims:     user.claims_hash,
        company_id: user.company_id
      }
    }
  end

  # Verifica y decodifica un JWT; retorna el payload o lanza excepción
  def self.decode_token(token)
    decoded = JWT.decode(
      token,
      SECRET_KEY,
      true,
      algorithm: "HS256"
    )
    HashWithIndifferentAccess.new(decoded.first)
  rescue JWT::ExpiredSignature
    raise AuthenticationError, "Token expirado"
  rescue JWT::DecodeError => e
    raise AuthenticationError, "Token inválido: #{e.message}"
  end

  private

  # Emite el JWT con roles (array) y claims (hash) consolidados
  #
  # Payload resultante:
  # {
  #   sub:        5,
  #   correo:     "admin_bogota@api.com",
  #   roles:      ["ADMIN"],
  #   claims:     { "ciudad" => "Bogota" },
  #   company_id: null,
  #   exp:        ...,
  #   iat:        ...
  # }
  def issue_token(user)
    payload = {
      sub:        user.id,
      correo:     user.correo,
      roles:      user.role_names,
      claims:     user.claims_hash,
      company_id: user.company_id,
      exp:        Time.now.to_i + TOKEN_EXPIRY,
      iat:        Time.now.to_i
    }
    JWT.encode(payload, SECRET_KEY, "HS256")
  end
end
