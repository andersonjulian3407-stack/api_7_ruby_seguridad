# ONION: Capa de Dominio — Interfaz del repositorio de empleados
# Define el contrato que debe cumplir cualquier implementación concreta
module EmployeeRepositoryInterface
  # Módulo 1: Operaciones base
  def all_employees = raise NotImplementedError
  def find_employee(id) = raise NotImplementedError
  def create_employee(data) = raise NotImplementedError
  def update_employee(id, data) = raise NotImplementedError
  def delete_employee(id) = raise NotImplementedError

  # Módulo 1: Colecciones y paginación
  def create_range(employees_data) = raise NotImplementedError
  def delete_range(ids) = raise NotImplementedError
  def get_paged(pagina:, tamano:, orden:, dir:, buscar:) = raise NotImplementedError
  def get_paged_by_company(company_id:, pagina:, tamano:) = raise NotImplementedError
  def patch_partial(id, cambios) = raise NotImplementedError
  def email_exists?(correo, except_id: nil) = raise NotImplementedError
end
