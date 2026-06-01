# Módulo 4: Pruebas de integración — endpoints de empleados
require "rails_helper"

RSpec.describe "Api::Employees", type: :request do
  let(:admin)   { create(:user, :admin) }
  let(:usuario) { create(:user) }

  def auth_header(user)
    token = AuthService.new.login(correo: user.correo, password: "password123")[:token]
    { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /api/empleados" do
    before { create_list(:employee, 5) }

    it "retorna 200 con estructura de paginación" do
      get "/api/empleados?pagina=1&tamano=3", headers: auth_header(usuario)
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include("datos", "pagina", "tamano", "total", "totalPaginas")
      expect(body["datos"].size).to be <= 3
    end

    it "retorna 400 si tamano es 0" do
      get "/api/empleados?pagina=1&tamano=0", headers: auth_header(usuario)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "POST /api/empleados" do
    let(:company) { create(:company) }

    it "crea un empleado y retorna 201" do
      payload = {
        employee: {
          nombre: "Laura", apellido: "Gómez", correo: "laura.test@x.com",
          cargo: "Dev", salario: 4000, company_id: company.id
        }
      }
      post "/api/empleados", params: payload, headers: auth_header(admin)
      expect(response).to have_http_status(:created)
    end

    it "retorna 422 si el correo es inválido" do
      payload = {
        employee: {
          nombre: "X", apellido: "Y", correo: "no-es-correo",
          cargo: "Dev", salario: 1000, company_id: company.id
        }
      }
      post "/api/empleados", params: payload, headers: auth_header(admin)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "retorna 401 sin token" do
      post "/api/empleados", params: { employee: {} }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/empleados/:id" do
    let(:company) { create(:company) }
    let(:emp)     { create(:employee, company: company) }

    it "actualiza parcialmente y retorna 200" do
      patch "/api/empleados/#{emp.id}",
            params: { cargo: "Líder Técnico" },
            headers: auth_header(admin)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["cargo"]).to eq("Líder Técnico")
    end
  end

  describe "POST /api/empleados/lote — creación masiva" do
    let(:company) { create(:company) }

    it "crea múltiples empleados y retorna 201" do
      payload = {
        empleados: [
          { nombre: "A", apellido: "B", correo: "ab.lote@x.com", cargo: "Dev", salario: 2000, company_id: company.id },
          { nombre: "C", apellido: "D", correo: "cd.lote@x.com", cargo: "QA",  salario: 2200, company_id: company.id }
        ]
      }
      post "/api/empleados/lote", params: payload, headers: auth_header(admin)
      expect(response).to have_http_status(:created)
    end
  end

  describe "DELETE /api/empleados/lote — eliminación múltiple" do
    it "elimina empleados seleccionados y retorna 200" do
      emps = create_list(:employee, 2)
      delete "/api/empleados/lote",
             params: { ids: emps.map(&:id) },
             headers: auth_header(admin)
      expect(response).to have_http_status(:ok)
    end

    it "retorna 403 si el usuario no es ADMIN" do
      emps = create_list(:employee, 1)
      delete "/api/empleados/lote",
             params: { ids: emps.map(&:id) },
             headers: auth_header(usuario)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
