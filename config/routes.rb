Rails.application.routes.draw do
  namespace :api do

    # ── Autenticación (Módulo 5) ─────────────────────────────────────────
    post "auth/registro", to: "auth#registro"
    post "auth/login",    to: "auth#login"
    get  "auth/perfil",   to: "auth#perfil"

    # ── Compañías ────────────────────────────────────────────────────────
    resources :companies, path: "companias" do
      collection do
        post :con_empleados
      end
      member do
        get :empleados
      end
    end

    # ── Empleados ────────────────────────────────────────────────────────
    resources :employees, path: "empleados" do
      collection do
        post   :lote, action: :bulk_create
        delete :lote, action: :bulk_destroy
      end
    end
  end

  # Raíz: responde JSON con info de la API
  root to: proc { [200, { "Content-Type" => "application/json" },
    ['{"status":"ok","api":"Companies API","version":"1.0","docs":"/api/auth/login"}'] ] }

  get "up" => "rails/health#show", as: :rails_health_check
end
