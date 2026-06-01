# ONION: Capa de Aplicacion - Logica de negocio y casos de uso de companias
class CompanyService
  def initialize(uow: UnitOfWork.new)
    @uow = uow
  end

  def get_all
    Rails.logger.info("[CompanyService] Consultando todas las companias")
    @uow.companies.all_companies
  end

  def get_by_id(id)
    Rails.logger.info("[CompanyService] Buscando compania ID: #{id}")
    @uow.companies.find_company(id)
  end

  def create(dto)
    Rails.logger.info("[CompanyService] Iniciando creacion de compania: #{dto.nombre}")
    dto.validate!

    @uow.transaction do |uow|
      company = uow.companies.create_company(dto.to_h)
      uow.save(company)
      Rails.logger.info("[CompanyService] Compania creada con ID: #{company.id}")
      company
    end
  end

  def update(id, dto)
    Rails.logger.info("[CompanyService] Actualizando compania ID: #{id}")
    dto.validate!

    @uow.transaction do |uow|
      company = uow.companies.update_company(id, dto.to_h)
      uow.save(company)
      Rails.logger.info("[CompanyService] Compania ID: #{id} actualizada")
      company
    end
  end

  def delete(id)
    Rails.logger.info("[CompanyService] Eliminando compania ID: #{id}")
    @uow.transaction do |uow|
      uow.companies.delete_company(id)
      Rails.logger.info("[CompanyService] Compania ID: #{id} eliminada")
    end
  end

  def employees_of(id)
    Rails.logger.info("[CompanyService] Consultando empleados de compania ID: #{id}")
    @uow.companies.employees_of(id)
  end

  def employees_paged(company_id:, pagina:, tamano:)
    Rails.logger.info("[CompanyService] Empleados paginados compania ID: #{company_id}")
    result = @uow.companies.employees_paged(
      company_id: company_id, pagina: pagina, tamano: tamano
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

  def create_with_employees(company_data, employees_data)
    Rails.logger.info("[UoW] INICIO TRANSACCION: crear compania con #{employees_data.size} empleado(s)")
    CompanyDto.new(company_data).validate!

    @uow.transaction do |uow|
      company = uow.companies.create_company(company_data)
      uow.save(company)
      Rails.logger.info("[UoW] Compania '#{company.nombre}' guardada (ID: #{company.id})")

      employees_data.each_with_index do |employee_data, index|
        employee_attrs = employee_data.merge(company_id: company.id)
        EmployeeDto.new(employee_attrs).validate!
        employee = uow.employees.create_employee(employee_attrs)
        uow.save(employee)
        Rails.logger.info("[UoW] Empleado #{index + 1}/#{employees_data.size} '#{employee.nombre}' guardado")
      end

      Rails.logger.info("[UoW] COMMIT: transaccion confirmada exitosamente")
      company.reload.as_json(include: :employees)
    end
  rescue => e
    Rails.logger.error("[UoW] ROLLBACK: transaccion revertida - #{e.message}")
    raise
  end
end
