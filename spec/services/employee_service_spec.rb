# Módulo 4: Pruebas unitarias del EmployeeService
require "rails_helper"

RSpec.describe EmployeeService, type: :service do
  let(:service) { EmployeeService.new }

  describe "#get_paged" do
    before { create_list(:employee, 15) }

    it "retorna la primera página con el tamaño correcto" do
      result = service.get_paged(pagina: 1, tamano: 5)
      expect(result[:datos].size).to eq(5)
      expect(result[:pagina]).to eq(1)
      expect(result[:tamano]).to eq(5)
      expect(result[:total]).to be >= 15
      expect(result[:totalPaginas]).to be >= 3
    end

    it "filtra por término de búsqueda" do
      emp    = create(:employee, nombre: "TerminoUnico")
      result = service.get_paged(pagina: 1, tamano: 10, buscar: "TerminoUnico")
      nombres = result[:datos].map(&:nombre)
      expect(nombres).to include("TerminoUnico")
    end
  end

  describe "#create_batch — creación masiva" do
    it "crea múltiples empleados en una transacción" do
      company = create(:company)
      data = [
        { nombre: "E1", apellido: "Test", correo: "e1batch@x.com", cargo: "Dev", salario: 1000, company_id: company.id },
        { nombre: "E2", apellido: "Test", correo: "e2batch@x.com", cargo: "QA",  salario: 1200, company_id: company.id }
      ]
      service.create_batch(data)
      expect(Employee.where(correo: ["e1batch@x.com", "e2batch@x.com"]).count).to eq(2)
    end

    it "hace rollback de todo el lote si uno es inválido" do
      company = create(:company)
      data = [
        { nombre: "OK", apellido: "Test", correo: "okbatch@x.com",  cargo: "Dev", salario: 1000, company_id: company.id },
        { nombre: "KO", apellido: "Test", correo: "correo-invalido",          cargo: "QA",  salario: -1,   company_id: company.id }
      ]
      expect { service.create_batch(data) }.to raise_error(ValidationError)
      expect(Employee.find_by(correo: "okbatch@x.com")).to be_nil
    end
  end

  describe "#delete_batch — eliminación múltiple" do
    it "elimina múltiples empleados en una transacción" do
      emps = create_list(:employee, 3)
      ids  = emps.map(&:id)
      service.delete_batch(ids)
      expect(Employee.where(id: ids).count).to eq(0)
    end
  end

  describe "#patch — actualización parcial" do
    it "actualiza solo los campos enviados" do
      emp    = create(:employee, cargo: "Junior")
      result = service.patch(emp.id, { cargo: "Senior" })
      expect(result.cargo).to eq("Senior")
      expect(result.nombre).to eq(emp.nombre)  # sin cambio
    end
  end
end
