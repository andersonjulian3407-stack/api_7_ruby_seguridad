# ONION: Capa de Presentación — Controlador de autenticación
# Módulo 5: JWT — Registro, Login, Perfil
# Módulo 6: Modelo Identity — roles y claims en request/response
module Api
  class AuthController < ApplicationController
    skip_before_action :authenticate_request!, only: [:registro, :login], raise: false

    # POST /api/auth/registro
    #
    # Body esperado:
    # {
    #   "nombre":     "Juan Pérez",
    #   "correo":     "juan@example.com",
    #   "password":   "Secret@123",
    #   "roles":      ["ADMIN"],             ← opcional, default: ["USUARIO"]
    #   "company_id": 1,                     ← opcional
    #   "claims": [                          ← opcional
    #     { "tipo": "ciudad", "valor": "Bogota" }
    #   ]
    # }
    def registro
      service = AuthService.new

      # Aceptar roles como array o string único (retrocompatibilidad)
      roles = if params[:roles].present?
                Array(params[:roles])
              elsif params[:rol].present?
                [params[:rol]]
              else
                ["USUARIO"]
              end

      # Aceptar claims como array de {tipo, valor}
      claims = Array(params[:claims])

      result = service.register(
        nombre:     params.require(:nombre),
        correo:     params.require(:correo),
        password:   params.require(:password),
        roles:      roles,
        company_id: params[:company_id],
        claims:     claims
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

    # GET /api/auth/perfil — requiere token
    def perfil
      authenticate_request!
      render json: {
        id:         current_user.id,
        nombre:     current_user.nombre,
        correo:     current_user.correo,
        roles:      current_user.role_names,
        claims:     current_user.claims_hash,
        company_id: current_user.company_id
      }, status: :ok
    end
  end
end
