# API Layer — ApplicationController base
# Módulo 3: Manejo global de errores
# Módulo 5: Autenticación JWT y autorización por roles
# Módulo 6: Autorización por políticas (ownership) y claims relacionales
class ApplicationController < ActionController::API

  # ── Manejo global de errores ───────────────────────────────────────────

  rescue_from ActiveRecord::RecordNotFound do |e|
    Rails.logger.warn("[API] 404 RecordNotFound: #{e.message}")
    render json: { error: "Recurso no encontrado: #{e.message}" }, status: :not_found
  end

  rescue_from ActionController::ParameterMissing do |e|
    Rails.logger.warn("[API] 400 ParameterMissing: #{e.message}")
    render json: { error: "Parámetro requerido faltante: #{e.message}" }, status: :bad_request
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    Rails.logger.warn("[API] 422 RecordInvalid: #{e.message}")
    errores = e.record.errors.map do |err|
      { campo: err.attribute.to_s, detalle: err.message }
    end
    render json: { mensaje: "Error de validación", errores: errores },
           status: :unprocessable_entity
  end

  rescue_from ValidationError do |e|
    Rails.logger.warn("[API] 422 ValidationError: #{e.message}")
    errores = e.field_errors.map { |m| { detalle: m } }
    render json: { mensaje: "Error de validación", errores: errores },
           status: :unprocessable_entity
  end

  rescue_from AuthenticationError do |e|
    render json: { error: e.message }, status: :unauthorized
  end

  rescue_from AuthorizationError do |e|
    render json: { error: e.message }, status: :forbidden
  end

  # ── Módulo 5: Autenticación JWT ────────────────────────────────────────

  def authenticate_request!
    header = request.headers["Authorization"]
    token  = header&.split(" ")&.last

    unless token
      raise AuthenticationError, "Token no proporcionado. Use: Authorization: Bearer <token>"
    end

    @current_payload = AuthService.decode_token(token)
    @current_user    = User.find_by(id: @current_payload[:sub])

    unless @current_user
      raise AuthenticationError, "Usuario del token no encontrado"
    end
  rescue AuthenticationError
    raise
  end

  def current_user
    @current_user
  end

  # ── Módulo 5: Autorización por roles ───────────────────────────────────
  #
  # Lee el array `roles` del payload JWT. Un usuario pasa si tiene
  # AL MENOS UNO de los roles requeridos (lógica OR, como ASP.NET [Authorize(Roles=...)])

  def authorize_roles!(*required_roles)
    user_roles = Array(@current_payload[:roles])
    unless current_user && (required_roles & user_roles).any?
      raise AuthorizationError,
            "Acceso denegado. Se requiere uno de estos roles: #{required_roles.join(', ')}"
    end
  end

  # ── Módulo 6: Política de propiedad (ownership) ────────────────────────
  #
  # Regla: un USUARIO solo puede modificar empleados de SU compañía.
  # Un ADMIN puede modificar cualquier empleado (exento de la política).

  def authorize_ownership!(employee_id)
    return if current_user.admin?

    employee = EmployeeRepository.new.find_employee(employee_id)

    unless current_user.company_id == employee.company_id
      raise AuthorizationError,
            "Política 'EsPropietarioDeCompania': solo puede modificar empleados de su propia compañía"
    end
  end

  # ── Módulo 6: Política de límite de salario ────────────────────────────
  #
  # Regla: solo un ADMIN puede asignar salarios por encima del umbral.
  SALARY_LIMIT = 50_000.freeze

  def authorize_salary_limit!(salario)
    return if current_user.admin?

    if salario.to_f > SALARY_LIMIT
      raise AuthorizationError,
            "Política 'LimiteSalario': solo ADMIN puede asignar salarios mayores a #{SALARY_LIMIT}"
    end
  end

  # ── Módulo 6: Política de Administración por Ciudad ────────────────────
  #
  # Lee los claims consolidados del payload JWT (incluye claims de usuario + rol).
  # Esto es equivalente a leer User.Claims en ASP.NET Core desde el HttpContext.

  # El administrador de Bogotá puede hacer CRUD completo EXCEPTO eliminar
  def authorize_delete_policy!
    claims = @current_payload[:claims] || {}
    if current_user.admin? && claims["ciudad"] == "Bogota"
      raise AuthorizationError,
            "Acceso denegado: El administrador de Bogotá no tiene permitido eliminar registros."
    end
  end

  # El administrador de Medellín puede hacer CRUD completo EXCEPTO PATCH
  def authorize_update_policy!
    claims = @current_payload[:claims] || {}
    if current_user.admin? && claims["ciudad"] == "Medellin"
      raise AuthorizationError,
            "Acceso denegado: El administrador de Medellin no tiene permitido actualizar registros."
    end
  end

  def authorize_patch_policy!
    claims = @current_payload[:claims] || {}
    if current_user.admin? && claims["ciudad"] == "Medellin"
      raise AuthorizationError,
            "Acceso denegado: El administrador de Medellín no tiene permitido realizar modificaciones parciales (PATCH)."
    end
  end
end
