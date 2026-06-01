# ONION: Capa de Aplicación - DTO con validaciones de entrada para Compañía
# Módulo 3: Validaciones usando Active Model Validations
class CompanyDto
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend  ActiveModel::Naming

  attr_accessor :nombre, :direccion, :telefono

  validates :nombre,    presence: true,
                        length: { minimum: 3, maximum: 100,
                                  message: "debe tener entre 3 y 100 caracteres" }
  validates :telefono,  presence: true,
                        format: { with: /\A\d{7,15}\z/,
                                  message: "solo debe contener dígitos (7-15 caracteres)" }
  validates :direccion, presence: true

  def initialize(attrs = {})
    attrs.each { |k, v| public_send(:"#{k}=", v) if respond_to?(:"#{k}=") }
  end

  def to_h
    { nombre: nombre, direccion: direccion, telefono: telefono }
  end

  def persisted?
    false
  end

  # Lanza ValidationError si hay errores; llamado desde el servicio
  def validate!
    raise ValidationError.new(errors.full_messages) unless valid?
  end
end
