# db/seeds.rb — Datos iniciales para la aplicación
# Módulo 6: Modelo Identity — roles y claims relacionales
puts "Sembrando datos iniciales..."

# ── Compañías ──────────────────────────────────────────────────────────────
companies_data = [
  { nombre: "TechCorp Colombia SAS", direccion: "Calle 72 # 10-07, Bogotá",     telefono: "6017234567" },
  { nombre: "InnovateSoft Ltda",     direccion: "Carrera 43A # 1-50, Medellín", telefono: "6044512345" },
  { nombre: "DataSystems SA",        direccion: "Av. Roosevelt # 38-57, Cali",  telefono: "6023456789" }
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
  { nombre: "Carlos",    apellido: "Ramírez",  correo: "carlos.ramirez@techcorp.com",    cargo: "Desarrollador Senior", salario: 8500000,  company: companies[0] },
  { nombre: "María",     apellido: "González", correo: "maria.gonzalez@techcorp.com",    cargo: "Líder de Proyecto",    salario: 12000000, company: companies[0] },
  { nombre: "Andrés",    apellido: "López",    correo: "andres.lopez@innovatesoft.com",   cargo: "QA Engineer",          salario: 6000000,  company: companies[1] },
  { nombre: "Valentina", apellido: "Díaz",     correo: "valentina.diaz@innovatesoft.com", cargo: "Data Scientist",       salario: 9500000,  company: companies[1] },
  { nombre: "Felipe",    apellido: "Torres",   correo: "felipe.torres@datasystems.com",   cargo: "DevOps Engineer",      salario: 7800000,  company: companies[2] }
]

employees_data.each do |data|
  Employee.find_or_create_by!(correo: data[:correo]) do |e|
    e.nombre   = data[:nombre]
    e.apellido = data[:apellido]
    e.cargo    = data[:cargo]
    e.salario  = data[:salario]
    e.company  = data[:company]
  end
end

puts "  ✓ #{employees_data.size} empleados creados"

# ── Roles base (estilo ASP.NET Identity) ──────────────────────────────────
admin_role   = Role.find_or_create_by!(nombre: "ADMIN")
usuario_role = Role.find_or_create_by!(nombre: "USUARIO")

puts "  ✓ Roles creados: ADMIN, USUARIO"

# ── Usuarios ──────────────────────────────────────────────────────────────
# NOTA: La contraseña NUNCA se almacena en texto plano.
# has_secure_password la hashea automáticamente con bcrypt.

# Admin Global — sin restricción de ciudad
admin = User.find_or_initialize_by(correo: "admin@api.com")
if admin.new_record?
  admin.nombre   = "Administrador Global"
  admin.password = ENV.fetch("ADMIN_PASSWORD", "Admin@1234!")
  admin.save!
  admin.roles << admin_role unless admin.roles.include?(admin_role)
  puts "  ✓ Usuario ADMIN Global creado: admin@api.com"
else
  admin.roles << admin_role unless admin.roles.include?(admin_role)
  puts "  ✓ Usuario ADMIN Global ya existe"
end

# Admin Bogotá — claim ciudad=Bogota (política: no puede eliminar)
admin_bogota = User.find_or_initialize_by(correo: "admin_bogota@api.com")
if admin_bogota.new_record?
  admin_bogota.nombre   = "Administrador Bogota"
  admin_bogota.password = ENV.fetch("ADMIN_PASSWORD", "Admin@1234!")
  admin_bogota.save!
  admin_bogota.roles << admin_role unless admin_bogota.roles.include?(admin_role)
  admin_bogota.user_claims.find_or_create_by!(claim_type: "ciudad", claim_value: "Bogota")
  puts "  ✓ Usuario ADMIN Bogotá creado: admin_bogota@api.com"
else
  admin_bogota.roles << admin_role unless admin_bogota.roles.include?(admin_role)
  admin_bogota.user_claims.find_or_create_by!(claim_type: "ciudad", claim_value: "Bogota")
  puts "  ✓ Usuario ADMIN Bogotá ya existe"
end

# Admin Medellín — claim ciudad=Medellin (política: no puede hacer PATCH)
admin_medellin = User.find_or_initialize_by(correo: "admin_medellin@api.com")
if admin_medellin.new_record?
  admin_medellin.nombre   = "Administrador Medellin"
  admin_medellin.password = ENV.fetch("ADMIN_PASSWORD", "Admin@1234!")
  admin_medellin.save!
  admin_medellin.roles << admin_role unless admin_medellin.roles.include?(admin_role)
  admin_medellin.user_claims.find_or_create_by!(claim_type: "ciudad", claim_value: "Medellin")
  puts "  ✓ Usuario ADMIN Medellín creado: admin_medellin@api.com"
else
  admin_medellin.roles << admin_role unless admin_medellin.roles.include?(admin_role)
  admin_medellin.user_claims.find_or_create_by!(claim_type: "ciudad", claim_value: "Medellin")
  puts "  ✓ Usuario ADMIN Medellín ya existe"
end

# Usuario Normal — rol USUARIO, pertenece a TechCorp
usuario = User.find_or_initialize_by(correo: "usuario@api.com")
if usuario.new_record?
  usuario.nombre     = "Usuario Normal"
  usuario.password   = ENV.fetch("USER_PASSWORD", "User@1234!")
  usuario.company_id = companies[0].id
  usuario.save!
  usuario.roles << usuario_role unless usuario.roles.include?(usuario_role)
  puts "  ✓ Usuario USUARIO creado: usuario@api.com"
else
  usuario.roles << usuario_role unless usuario.roles.include?(usuario_role)
  puts "  ✓ Usuario USUARIO ya existe"
end

puts "\n¡Datos iniciales sembrados exitosamente!"
puts "  Admin Global:   admin@api.com            / Admin@1234!"
puts "  Admin Bogotá:   admin_bogota@api.com     / Admin@1234!"
puts "  Admin Medellín: admin_medellin@api.com   / Admin@1234!"
puts "  Usuario:        usuario@api.com          / User@1234!"
