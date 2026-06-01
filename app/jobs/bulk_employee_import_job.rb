# ONION: Capa de Infraestructura — Active Job
# Módulo 2: Alternativa idiomática de asincronía en Rails
# Active Job + Solid Queue permite procesar tareas pesadas fuera del hilo HTTP
# Equivalente a IHostedService / BackgroundService de ASP.NET Core

class BulkEmployeeImportJob < ApplicationJob
  queue_as :default

  # Se ejecuta de forma asíncrona por Solid Queue (background worker)
  # El hilo de Puma queda libre para nuevas peticiones HTTP inmediatamente
  def perform(employees_data, company_id)
    Rails.logger.info("[BulkEmployeeImportJob] Iniciando importación de #{employees_data.size} empleados en background")

    service = EmployeeService.new
    parsed  = employees_data.map do |d|
      d.symbolize_keys.merge(company_id: company_id)
    end

    service.create_batch(parsed)
    Rails.logger.info("[BulkEmployeeImportJob] Importación completada exitosamente")
  rescue => e
    Rails.logger.error("[BulkEmployeeImportJob] Error en importación: #{e.message}")
    raise  # Re-raise para que Solid Queue pueda reintentar el job
  end
end
