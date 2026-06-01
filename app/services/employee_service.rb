# ONION: Capa de Aplicacion - Logica de negocio y casos de uso de empleados
class EmployeeService
  def initialize(uow: UnitOfWork.new)
    @uow = uow
  end

  def get_all
    Rails.logger.info("[EmployeeService] Consultando todos los empleados")
    @uow.employees.all_employees
  end

  def get_by_id(id)
    Rails.logger.info("[EmployeeService] Buscando empleado ID: #{id}")
    @uow.employees.find_employee(id)
  end

  def create(dto)
    Rails.logger.info("[EmployeeService] Creando empleado: #{dto.nombre} #{dto.apellido}")
    dto.validate!
    validate_email_unique!(dto.correo)
    validate_company_exists!(dto.company_id)

    @uow.transaction do |uow|
      employee = uow.employees.create_employee(dto.to_h)
      uow.save(employee)
      Rails.logger.info("[EmployeeService] Empleado creado con ID: #{employee.id}")
      employee
    end
  end

  def update(id, dto)
    Rails.logger.info("[EmployeeService] Actualizando empleado ID: #{id}")
    dto.validate!
    validate_email_unique!(dto.correo, except_id: id)
    validate_company_exists!(dto.company_id)

    @uow.transaction do |uow|
      employee = uow.employees.update_employee(id, dto.to_h)
      uow.save(employee)
      Rails.logger.info("[EmployeeService] Empleado ID: #{id} actualizado")
      employee
    end
  end

  def delete(id)
    Rails.logger.info("[EmployeeService] Eliminando empleado ID: #{id}")
    @uow.transaction do |uow|
      uow.employees.delete_employee(id)
      Rails.logger.info("[EmployeeService] Empleado ID: #{id} eliminado")
    end
  end

  def get_paged(pagina:, tamano:, orden: "nombre", dir: "asc", buscar: nil)
    Rails.logger.info("[EmployeeService] Listado paginado pagina:#{pagina} tamano:#{tamano} buscar:#{buscar}")
    result = @uow.employees.get_paged(
      pagina: pagina, tamano: tamano, orden: orden, dir: dir, buscar: buscar
    )
    pages = (result[:total].to_f / tamano.to_i).ceil
    {
      datos: result[:data],
      pagina: pagina.to_i,
      tamano: tamano.to_i,
      total: result[:total],
      totalPaginas: pages
    }
  end

  def create_batch(employees_data)
    Rails.logger.info("[EmployeeService] Creacion masiva de #{employees_data.size} empleado(s)")
    @uow.transaction do |uow|
      employees_data.each do |data|
        dto = EmployeeDto.new(data)
        dto.validate!
        validate_email_unique!(dto.correo)
        validate_company_exists!(dto.company_id)

        employee = uow.employees.create_employee(dto.to_h)
        uow.save(employee)
        Rails.logger.info("[EmployeeService] Empleado '#{employee.nombre}' creado en lote")
      end
      Rails.logger.info("[EmployeeService] Creacion masiva completada - COMMIT")
    end
  end

  def delete_batch(ids)
    Rails.logger.info("[EmployeeService] Eliminacion multiple de IDs: #{ids.inspect}")
    @uow.transaction do |uow|
      count = uow.employees.delete_range(ids)
      Rails.logger.info("[EmployeeService] #{count} empleado(s) eliminados en lote - COMMIT")
      count
    end
  end

  def patch(id, changes)
    Rails.logger.info("[EmployeeService] PATCH empleado ID: #{id} campos: #{changes.keys.inspect}")
    validate_email_unique!(changes[:correo], except_id: id) if changes[:correo].present?
    validate_company_exists!(changes[:company_id]) if changes.key?(:company_id)

    @uow.transaction do |uow|
      employee = uow.employees.patch_partial(id, changes)
      uow.save(employee)
      Rails.logger.info("[EmployeeService] PATCH empleado ID: #{id} completado")
      employee
    end
  end

  private

  def validate_company_exists!(company_id)
    return if company_id.blank?
    unless @uow.companies.exists?(company_id)
      raise ActiveRecord::RecordNotFound, "Compania con ID #{company_id} no existe"
    end
  end

  def validate_email_unique!(correo, except_id: nil)
    return if correo.blank?
    if @uow.employees.email_exists?(correo, except_id: except_id)
      raise ValidationError.new(["Correo ya esta registrado en el sistema"])
    end
  end
end
