# ONION: Capa de Presentación — Controlador de autenticación
# Módulo 5: JWT — Registro, Login, Perfil
module Api
  class AuthController < ApplicationController
    # Endpoints públicos: no requieren token
    skip_before_action :authenticate_request!, only: [:registro, :login], raise: false

    # POST /api/auth/registro
    def registro
      service = AuthService.new
      result  = service.register(
        nombre:     params.require(:nombre),
        correo:     params.require(:correo),
        password:   params.require(:password),
        rol:        params[:rol] || "USUARIO",
        company_id: params[:company_id]
      )
      render json: result, status: :created
    end

    # POST /api/auth/login
    def login
      service = AuthService.new
      result  = service.login(
        correo:   params.require(:correo),
        password: params.require(:password)
      )
      render json: result, status: :ok
    end

    # GET /api/auth/perfil  — requiere token
    def perfil
      authenticate_request!
      render json: {
        id:         current_user.id,
        nombre:     current_user.nombre,
        correo:     current_user.correo,
        rol:        current_user.rol,
        company_id: current_user.company_id
      }, status: :ok
    end
  end
end
