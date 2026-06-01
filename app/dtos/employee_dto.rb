# ONION: Capa de Aplicacion - DTO con validaciones de entrada para Empleado
# Modulo 3: Validaciones usando Active Model Validations
class EmployeeDto
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :nombre, :apellido, :correo, :cargo, :salario, :company_id

  validates :nombre, presence: true, length: { minimum: 1, maximum: 100 }
  validates :apellido, presence: true, length: { minimum: 1, maximum: 100 }
  validates :correo, presence: true,
                     format: { with: URI::MailTo::EMAIL_REGEXP,
                               message: "no tiene formato de correo valido" }
  validates :cargo, presence: true
  validates :salario, presence: true,
                      numericality: { greater_than: 0,
                                      message: "debe ser mayor que 0" }
  validates :company_id, presence: true

  def initialize(attrs = {})
    attrs.each { |k, v| public_send(:"#{k}=", v) if respond_to?(:"#{k}=") }
  end

  def to_h
    {
      nombre: nombre,
      apellido: apellido,
      correo: correo,
      cargo: cargo,
      salario: salario,
      company_id: company_id
    }
  end

  def persisted?
    false
  end

  def validate!
    raise ValidationError.new(errors.full_messages) unless valid?
  end
end
