# ONION: Capa de Presentacion - endpoints HTTP de empleados
module Api
  class EmployeesController < ApplicationController
    before_action :authenticate_request!
    before_action :set_service

    def index
      pagina = (params[:pagina] || 1).to_i
      tamano = (params[:tamano] || 10).to_i
      orden = params[:orden] || "nombre"
      dir = params[:dir] || "asc"
      buscar = params[:buscar]

      if pagina < 1 || tamano < 1 || tamano > 100
        return render json: {
          error: "Parametros invalidos: pagina >= 1, tamano entre 1 y 100"
        }, status: :bad_request
      end

      result = @service.get_paged(pagina: pagina, tamano: tamano, orden: orden, dir: dir, buscar: buscar)
      render json: {
        datos: result[:datos],
        pagina: result[:pagina],
        tamano: result[:tamano],
        total: result[:total],
        totalPaginas: result[:totalPaginas]
      }, status: :ok
    end

    def show
      render json: @service.get_by_id(params[:id]), status: :ok
    end

    def create
      authorize_roles!("ADMIN", "USUARIO")
      authorize_salary_limit!(params.dig(:employee, :salario).to_f)
      dto = EmployeeDto.new(employee_params)
      render json: @service.create(dto), status: :created
    end

    def update
      authorize_roles!("ADMIN", "USUARIO")
      authorize_ownership!(params[:id])
      authorize_update_policy!

      if request.patch?
        authorize_salary_limit!(patch_source_params[:salario].to_f) if patch_source_params[:salario]
        result = @service.patch(params[:id], employee_patch_params)
      else
        authorize_salary_limit!(params.dig(:employee, :salario).to_f) if params.dig(:employee, :salario)
        dto = EmployeeDto.new(employee_params)
        result = @service.update(params[:id], dto)
      end

      render json: result, status: :ok
    end

    def destroy
      authorize_roles!("ADMIN")
      authorize_delete_policy!
      @service.delete(params[:id])
      head :no_content
    end

    def bulk_create
      authorize_roles!("ADMIN", "USUARIO")
      employees_data = params.require(:empleados).map do |employee|
        employee.permit(:nombre, :apellido, :correo, :cargo, :salario, :company_id)
                .to_h.symbolize_keys
      end

      employees_data.each do |employee|
        authorize_salary_limit!(employee[:salario].to_f) if employee[:salario]
      end

      @service.create_batch(employees_data)
      render json: { mensaje: "#{employees_data.size} empleado(s) creados exitosamente" },
             status: :created
    end

    def bulk_destroy
      authorize_roles!("ADMIN")
      authorize_delete_policy!
      ids = params.require(:ids)
      count = @service.delete_batch(ids)
      render json: { mensaje: "#{count} empleado(s) eliminados exitosamente" },
             status: :ok
    end

    private

    def set_service
      @service = EmployeeService.new
    end

    def employee_params
      params.require(:employee)
            .permit(:nombre, :apellido, :correo, :cargo, :salario, :company_id)
            .to_h.symbolize_keys
    end

    def employee_patch_params
      allowed = %i[nombre apellido correo cargo salario company_id]
      patch_source_params.permit(*allowed).to_h.symbolize_keys.reject { |_, value| value.nil? }
    end

    def patch_source_params
      params[:employee].present? ? params.require(:employee) : params
    end
  end
end
