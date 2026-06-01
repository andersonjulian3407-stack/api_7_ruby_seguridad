Rails.application.routes.draw do
  namespace :api do

    # ── Autenticación (Módulo 5) ─────────────────────────────────────────
    post "auth/registro", to: "auth#registro"
    post "auth/login",    to: "auth#login"
    get  "auth/perfil",   to: "auth#perfil"

    # ── Compañías ────────────────────────────────────────────────────────
    resources :companies, path: "companias" do
      collection do
        post :con_empleados   # POST /api/companias/con_empleados — transaccional (ADMIN)
      end
      member do
        get :empleados         # GET /api/companias/:id/empleados?pagina=&tamano=
      end
    end

    # ── Empleados ────────────────────────────────────────────────────────
    resources :employees, path: "empleados" do
      collection do
        post   :lote,           action: :bulk_create    # POST /api/empleados/lote
        delete :lote,           action: :bulk_destroy   # DELETE /api/empleados/lote
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
