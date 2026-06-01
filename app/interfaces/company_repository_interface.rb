# ONION: Capa de Dominio — Interfaz del repositorio de compañías
module CompanyRepositoryInterface
  def all_companies = raise NotImplementedError
  def find_company(id) = raise NotImplementedError
  def create_company(data) = raise NotImplementedError
  def update_company(id, data) = raise NotImplementedError
  def delete_company(id) = raise NotImplementedError
  def employees_of(id) = raise NotImplementedError
  def employees_paged(company_id:, pagina:, tamano:) = raise NotImplementedError
  def exists?(id) = raise NotImplementedError
end
