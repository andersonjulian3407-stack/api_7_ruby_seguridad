# Módulo 4: Pruebas de integración — endpoints de autenticación
require "rails_helper"

RSpec.describe "Api::Auth", type: :request do
  describe "POST /api/auth/registro" do
    it "registra un usuario nuevo y retorna 201" do
      post "/api/auth/registro", params: {
        nombre: "Test User", correo: "nuevo@test.com", password: "secret123"
      }
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include("id", "correo", "roles")
    end

    it "registra roles y claims relacionales" do
      post "/api/auth/registro", params: {
        nombre: "Admin Bogota",
        correo: "admin.nuevo@test.com",
        password: "secret123",
        roles: ["ADMIN", "USUARIO"],
        claims: [{ tipo: "ciudad", valor: "Bogota" }]
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["roles"]).to match_array(["ADMIN", "USUARIO"])
      expect(body["claims"]).to include("ciudad" => "Bogota")
    end

    it "retorna 422 si el correo ya existe" do
      create(:user, correo: "dup@test.com")
      post "/api/auth/registro", params: {
        nombre: "Otro", correo: "dup@test.com", password: "secret123"
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/auth/login" do
    let!(:user) { create(:user, correo: "login@test.com") }

    it "devuelve token JWT con credenciales correctas" do
      post "/api/auth/login", params: { correo: "login@test.com", password: "password123" }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include("token", "tipo", "usuario")
      expect(body["tipo"]).to eq("Bearer")
      payload = AuthService.decode_token(body["token"])
      expect(payload[:roles]).to include("USUARIO")
      expect(payload).to include(:claims)
    end

    it "retorna 401 con contraseña incorrecta" do
      post "/api/auth/login", params: { correo: "login@test.com", password: "wrong" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/auth/perfil" do
    let(:user) { create(:user) }

    it "retorna perfil con token válido" do
      post "/api/auth/login", params: { correo: user.correo, password: "password123" }
      token = JSON.parse(response.body)["token"]

      get "/api/auth/perfil", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["correo"]).to eq(user.correo)
    end

    it "retorna 401 sin token" do
      get "/api/auth/perfil"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
