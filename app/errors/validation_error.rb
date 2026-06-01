# Error personalizado para validaciones de la capa Application
# Módulo 3: Manejo centralizado de errores de validación
class ValidationError < StandardError
  attr_reader :field_errors

  def initialize(messages)
    @field_errors = messages
    super(messages.join(", "))
  end
end
