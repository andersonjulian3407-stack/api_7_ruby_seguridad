# API Layer — ApplicationController base
# Módulo 3: Manejo global de errores
# Módulo 5: Autenticación JWT y autorización por roles
# Módulo 6: Autorización por políticas (ownership)
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

  # Módulo 3: errores de validación del ORM → 422 con formato uniforme
  rescue_from ActiveRecord::RecordInvalid do |e|
    Rails.logger.warn("[API] 422 RecordInvalid: #{e.message}")
    errores = e.record.errors.map do |err|
      { campo: err.attribute.to_s, detalle: err.message }
    end
    render json: { mensaje: "Error de validación", errores: errores },
           status: :unprocessable_entity
  end

  # Módulo 3: errores del DTO (capa Application)
  rescue_from ValidationError do |e|
    Rails.logger.warn("[API] 422 ValidationError: #{e.message}")
    errores = e.field_errors.map { |m| { detalle: m } }
    render json: { mensaje: "Error de validación", errores: errores },
           status: :unprocessable_entity
  end

  # Módulo 5: autenticación fallida → 401
  rescue_from AuthenticationError do |e|
    render json: { error: e.message }, status: :unauthorized
  end

  # Módulo 5/6: autorización fallida → 403
  rescue_from AuthorizationError do |e|
    render json: { error: e.message }, status: :forbidden
  end

  # ── Módulo 5: Autenticación JWT ────────────────────────────────────────

  # Extrae y verifica el JWT del header Authorization: Bearer <token>
  # Pone el usuario en @current_user
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

  # Verifica que el usuario autenticado tenga uno de los roles permitidos
  def authorize_roles!(*roles)
    unless current_user && roles.include?(current_user.rol)
      raise AuthorizationError,
            "Acceso denegado. Se requiere uno de estos roles: #{roles.join(', ')}"
    end
  end

  # ── Módulo 6: Política de propiedad (ownership) ────────────────────────
  #
  # Equivalente a ASP.NET Core:
  #   [Authorize(Policy = "EsPropietarioDeCompania")]
  #   con EsPropietarioHandler que evalúa claims vs. recurso
  #
  # Regla: un USUARIO solo puede modificar empleados de SU compañía.
  # Un ADMIN puede modificar cualquier empleado (exento de la política).

  def authorize_ownership!(employee_id)
    return if current_user.admin?  # ADMIN no tiene restricción

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
end
