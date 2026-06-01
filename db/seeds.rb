# db/seeds.rb — Datos iniciales para la aplicación
puts "Sembrando datos iniciales..."

# ── Compañías ──────────────────────────────────────────────────────────────
companies_data = [
  { nombre: "TechCorp Colombia SAS", direccion: "Calle 72 # 10-07, Bogotá", telefono: "6017234567" },
  { nombre: "InnovateSoft Ltda",     direccion: "Carrera 43A # 1-50, Medellín", telefono: "6044512345" },
  { nombre: "DataSystems SA",        direccion: "Av. Roosevelt # 38-57, Cali", telefono: "6023456789" }
]

companies = companies_data.map do |data|
  Company.find_or_create_by!(nombre: data[:nombre]) do |c|
    c.direccion = data[:direccion]
    c.telefono  = data[:telefono]
  end
end

puts "  ✓ #{companies.size} compañías creadas"

# ── Empleados ──────────────────────────────────────────────────────────────
employees_data = [
  { nombre: "Carlos",   apellido: "Ramírez",  correo: "carlos.ramirez@techcorp.com",  cargo: "Desarrollador Senior", salario: 8500000,  company: companies[0] },
  { nombre: "María",    apellido: "González", correo: "maria.gonzalez@techcorp.com",  cargo: "Líder de Proyecto",    salario: 12000000, company: companies[0] },
  { nombre: "Andrés",   apellido: "López",    correo: "andres.lopez@innovatesoft.com", cargo: "QA Engineer",          salario: 6000000,  company: companies[1] },
  { nombre: "Valentina",apellido: "Díaz",     correo: "valentina.diaz@innovatesoft.com",cargo:"Data Scientist",       salario: 9500000,  company: companies[1] },
  { nombre: "Felipe",   apellido: "Torres",   correo: "felipe.torres@datasystems.com", cargo: "DevOps Engineer",      salario: 7800000,  company: companies[2] }
]

employees_data.each do |data|
  Employee.find_or_create_by!(correo: data[:correo]) do |e|
    e.nombre    = data[:nombre]
    e.apellido  = data[:apellido]
    e.cargo     = data[:cargo]
    e.salario   = data[:salario]
    e.company   = data[:company]
  end
end

puts "  ✓ #{employees_data.size} empleados creados"

# ── Usuarios (Módulo 5) ────────────────────────────────────────────────────
# NOTA: La contraseña NUNCA se almacena en texto plano.
# has_secure_password la hashea automáticamente con bcrypt.
admin = User.find_or_initialize_by(correo: "admin@api.com")
if admin.new_record?
  admin.nombre   = "Administrador"
  admin.password = ENV.fetch("ADMIN_PASSWORD", "Admin@1234!")
  admin.rol      = "ADMIN"
  admin.save!
  puts "  ✓ Usuario ADMIN creado: admin@api.com"
else
  puts "  ✓ Usuario ADMIN ya existe"
end

usuario = User.find_or_initialize_by(correo: "usuario@api.com")
if usuario.new_record?
  usuario.nombre     = "Usuario Normal"
  usuario.password   = ENV.fetch("USER_PASSWORD", "User@1234!")
  usuario.rol        = "USUARIO"
  usuario.company_id = companies[0].id  # Pertenece a TechCorp para probar políticas
  usuario.save!
  puts "  ✓ Usuario USUARIO creado: usuario@api.com"
else
  puts "  ✓ Usuario USUARIO ya existe"
end

puts "\n¡Datos iniciales sembrados exitosamente!"
puts "  Admin:   admin@api.com   / Admin@1234!"
puts "  Usuario: usuario@api.com / User@1234!"
