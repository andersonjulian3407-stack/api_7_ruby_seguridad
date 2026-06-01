# ONION: Capa de Aplicación — Servicio de autenticación
# Módulo 5: JWT — registro, login, emisión y verificación de tokens
require "jwt"
require "bcrypt"

class AuthService
  SECRET_KEY = ENV.fetch("JWT_SECRET_KEY") { Rails.application.secret_key_base }
  TOKEN_EXPIRY = 24 * 60 * 60  # 24 horas en segundos

  # Registro: crea usuario con contraseña hasheada (bcrypt via has_secure_password)
  # NUNCA almacena la contraseña en texto plano
  def register(nombre:, correo:, password:, rol: "USUARIO", company_id: nil)
    Rails.logger.info("[AuthService] Registrando usuario: #{correo}")

    if User.exists?(correo: correo)
      raise ValidationError.new(["El correo #{correo} ya está registrado"])
    end

    unless User::ROLES.include?(rol)
      raise ValidationError.new(["Rol inválido. Debe ser: #{User::ROLES.join(', ')}"])
    end

    user = User.new(
      nombre:     nombre,
      correo:     correo,
      password:   password,   # has_secure_password hashea esto con bcrypt
      rol:        rol,
      company_id: company_id
    )

    unless user.save
      raise ValidationError.new(user.errors.full_messages)
    end

    Rails.logger.info("[AuthService] Usuario registrado con ID: #{user.id}")
    { id: user.id, nombre: user.nombre, correo: user.correo, rol: user.rol }
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
      token:  token,
      tipo:   "Bearer",
      expira_en: TOKEN_EXPIRY,
      usuario: { id: user.id, nombre: user.nombre, correo: user.correo, rol: user.rol }
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

  def issue_token(user)
    payload = {
      sub:        user.id,
      correo:     user.correo,
      rol:        user.rol,
      company_id: user.company_id,
      exp:        Time.now.to_i + TOKEN_EXPIRY,
      iat:        Time.now.to_i
    }
    JWT.encode(payload, SECRET_KEY, "HS256")
  end
end
