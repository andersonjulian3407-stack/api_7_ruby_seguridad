# ONION: Capa Externa (UI/Presentación) - Recibe peticiones HTTP y responde con JSON
module Api
  class CompaniesController < ApplicationController
    before_action :authenticate_request!, except: []
    before_action :set_service

    # GET /api/companias
    def index
      render json: @service.get_all, status: :ok
    end

    # GET /api/companias/:id
    def show
      render json: @service.get_by_id(params[:id]), status: :ok
    end

    # POST /api/companias
    def create
      authorize_roles!("ADMIN", "USUARIO")
      dto = CompanyDto.new(company_params)
      render json: @service.create(dto), status: :created
    end

    # PUT/PATCH /api/companias/:id
    def update
      authorize_roles!("ADMIN", "USUARIO")
      dto = CompanyDto.new(company_params)
      render json: @service.update(params[:id], dto), status: :ok
    end

    # DELETE /api/companias/:id
    def destroy
      authorize_roles!("ADMIN")
      @service.delete(params[:id])
      head :no_content
    end

    # GET /api/companias/:id/empleados?pagina=1&tamano=10
    def empleados
      pagina = (params[:pagina] || 1).to_i
      tamano = (params[:tamano] || 10).to_i

      if pagina < 1 || tamano < 1
        return render json: { error: "pagina y tamano deben ser >= 1" }, status: :bad_request
      end

      result = @service.employees_paged(
        company_id: params[:id], pagina: pagina, tamano: tamano
      )
      render json: {
        datos:        result[:datos],
        pagina:       result[:pagina],
        tamano:       result[:tamano],
        total:        result[:total],
        totalPaginas: result[:totalPaginas]
      }, status: :ok
    end

    # POST /api/companias/con_empleados — endpoint transaccional (Solo ADMIN)
    def con_empleados
      authorize_roles!("ADMIN")
      company_data = params.require(:company)
                           .permit(:nombre, :direccion, :telefono)
                           .to_h.symbolize_keys

      employees_data = params.require(:empleados).map do |e|
        e.permit(:nombre, :apellido, :correo, :cargo, :salario)
         .to_h.symbolize_keys
      end

      result = @service.create_with_employees(company_data, employees_data)
      render json: result, status: :created
    end

    private

    def set_service
      @service = CompanyService.new
    end

    def company_params
      params.require(:company).permit(:nombre, :direccion, :telefono).to_h.symbolize_keys
    end
  end
end
