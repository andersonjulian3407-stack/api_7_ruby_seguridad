# Módulo 4: Pruebas unitarias del CompanyService
require "rails_helper"

RSpec.describe CompanyService, type: :service do
  let(:uow)     { UnitOfWork.new }
  let(:service) { CompanyService.new(uow: uow) }

  describe "#get_all" do
    it "retorna todas las compañías" do
      create_list(:company, 3)
      result = service.get_all
      expect(result.count).to be >= 3
    end
  end

  describe "#get_by_id" do
    it "retorna la compañía correcta" do
      company = create(:company)
      result  = service.get_by_id(company.id)
      expect(result.id).to eq(company.id)
      expect(result.nombre).to eq(company.nombre)
    end

    it "lanza RecordNotFound para ID inexistente" do
      expect { service.get_by_id(999999) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "#create" do
    it "crea una compañía válida" do
      dto    = CompanyDto.new(nombre: "Tech SA", direccion: "Calle 1", telefono: "3001234567")
      result = service.create(dto)
      expect(result.id).not_to be_nil
      expect(result.nombre).to eq("Tech SA")
    end
  end

  describe "#update" do
    it "actualiza el nombre de la compañía" do
      company = create(:company)
      dto     = CompanyDto.new(nombre: "Nuevo Nombre", direccion: company.direccion, telefono: company.telefono)
      result  = service.update(company.id, dto)
      expect(result.nombre).to eq("Nuevo Nombre")
    end
  end

  describe "#delete" do
    it "elimina la compañía" do
      company = create(:company)
      service.delete(company.id)
      expect { Company.find(company.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  # ── Prueba del CASO TRANSACCIONAL (Módulo 4 — obligatoria) ──────────────
  #
  # Verifica que el rollback funciona: si un empleado falla,
  # NI la compañía NI los empleados anteriores quedan en la BD.
  describe "#create_with_employees — ROLLBACK TRANSACCIONAL" do
    it "hace rollback total si un empleado tiene datos inválidos" do
      company_data   = { nombre: "Empresa Rollback", direccion: "Dir 1", telefono: "3001111111" }
      employees_data = [
        { nombre: "Juan", apellido: "Pérez",  correo: "juan@ok.com",  cargo: "Dev", salario: 3000 },
        { nombre: "Ana",  apellido: "López",   correo: "correo-invalido",  cargo: "QA",  salario: -500 }  # ← inválido
      ]

      expect {
        service.create_with_employees(company_data, employees_data)
      }.to raise_error(ValidationError)

      # La compañía NO debe existir en la BD
      expect(Company.find_by(nombre: "Empresa Rollback")).to be_nil
      # Tampoco el primer empleado
      expect(Employee.find_by(correo: "juan@ok.com")).to be_nil
    end

    it "hace commit cuando todos los datos son válidos" do
      company_data   = { nombre: "Empresa OK", direccion: "Dir 2", telefono: "3002222222" }
      employees_data = [
        { nombre: "Carlos", apellido: "Ruiz", correo: "carlos.ruiz@ok.com", cargo: "Dev", salario: 5000 }
      ]

      result = service.create_with_employees(company_data, employees_data)
      expect(Company.find_by(nombre: "Empresa OK")).not_to be_nil
      expect(Employee.find_by(correo: "carlos.ruiz@ok.com")).not_to be_nil
    end
  end
end
