# ONION: Capa de Infraestructura - Repositorio concreto que implementa EmployeeRepositoryInterface usando el ORM
# REGLA CLAVE: los métodos create/update NO llaman .save — eso lo hace el Unit of Work
class EmployeeRepository
  include EmployeeRepositoryInterface

  # Retorna todos los empleados con eager loading de su compañía
  def all_employees
    Employee.includes(:company).all
  end

  # Busca un empleado por ID — lanza ActiveRecord::RecordNotFound si no existe
  def find_employee(id)
    Employee.find(id)
  end

  # Construye el objeto pero NO lo persiste (responsabilidad del UoW)
  def create_employee(data)
    Employee.new(data)
  end

  # Asigna atributos pero NO llama save (responsabilidad del UoW)
  def update_employee(id, data)
    employee = find_employee(id)
    employee.assign_attributes(data)
    employee
  end

  # Destruye el registro inmediatamente
  def delete_employee(id)
    find_employee(id).destroy
  end

  # ── MÓDULO 1: Operaciones sobre colecciones ─────────────────────────────

  # Construye múltiples objetos Employee sin persistirlos (UoW los guarda)
  def create_range(employees_data)
    employees_data.map { |data| Employee.new(data) }
  end

  # Marca múltiples empleados para eliminación; el UoW llama destroy dentro
  # de la transacción. Retorna el número de registros eliminados.
  def delete_range(ids)
    employees = Employee.where(id: ids)
    missing = ids.map(&:to_i) - employees.map(&:id)
    raise ActiveRecord::RecordNotFound, "Empleados no encontrados: #{missing.join(', ')}" if missing.any?
    employees.each(&:destroy)
    employees.size
  end

  # Paginación + filtrado + ordenamiento
  # Retorna { data: [...], total: N }
  ALLOWED_ORDER_COLUMNS = %w[nombre apellido correo cargo salario].freeze

  def get_paged(pagina:, tamano:, orden: "nombre", dir: "asc", buscar: nil)
    scope = Employee.includes(:company)

    # Filtro de búsqueda
    if buscar.present?
      term = "%#{buscar}%"
      scope = scope.where(
        "employees.nombre LIKE :t OR employees.apellido LIKE :t OR employees.correo LIKE :t",
        t: term
      )
    end

    # Ordenamiento seguro (evitar SQL injection)
    col = ALLOWED_ORDER_COLUMNS.include?(orden.to_s) ? orden.to_s : "nombre"
    direction = dir.to_s.downcase == "desc" ? "DESC" : "ASC"
    scope = scope.order("employees.#{col} #{direction}")

    total = scope.count
    offset = (pagina.to_i - 1) * tamano.to_i
    data   = scope.offset(offset).limit(tamano.to_i)

    { data: data, total: total }
  end

  # Paginación de empleados por compañía
  def get_paged_by_company(company_id:, pagina:, tamano:)
    scope = Employee.where(company_id: company_id)
    total = scope.count
    data  = scope.offset((pagina.to_i - 1) * tamano.to_i).limit(tamano.to_i)
    { data: data, total: total }
  end

  # Actualización parcial (PATCH): solo los campos presentes en `cambios`
  def patch_partial(id, cambios)
    employee = find_employee(id)
    employee.assign_attributes(cambios)
    employee
  end

  def email_exists?(correo, except_id: nil)
    scope = Employee.where(correo: correo)
    scope = scope.where.not(id: except_id) if except_id.present?
    scope.exists?
  end
end
