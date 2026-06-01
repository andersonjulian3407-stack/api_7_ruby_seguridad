# API REST — Ruby on Rails · Parte II
**SENA · CEET — Construcción de una API REST**  
Tecnología: Ruby on Rails 8.1 · Active Record · SQL Server

---

## Índice rápido
- [Instalación y arranque](#instalación-y-arranque)
- [Variables de entorno](#variables-de-entorno)
- [CRUD de colecciones](#crud-de-colecciones)
- [Programación asíncrona](#programación-asíncrona)
- [Validaciones](#validaciones)
- [Pruebas](#pruebas)
- [Seguridad — JWT](#seguridad--jwt)
- [Comparación con ASP.NET Core](#comparación-con-aspnet-core)
- [Conclusiones Parte II](#conclusiones-parte-ii)

---

## Instalación y arranque

```bash
# 1. Clonar y entrar al proyecto
git clone <repo> && cd api_6_ruby

# 2. Copiar variables de entorno
cp .env.example .env
# Editar .env con sus valores reales

# 3. Instalar dependencias
bundle install

# 4. Crear BD, ejecutar migraciones y sembrar datos
bin/rails db:create db:migrate db:seed

# 5. Levantar el servidor
bin/rails server
```

---

## Variables de entorno

| Variable | Descripción | Obligatorio |
|---|---|---|
| `JWT_SECRET_KEY` | Clave secreta para firmar tokens JWT | ✅ Sí |
| `DB_HOST` / `DB_NAME` / `DB_USERNAME` / `DB_PASSWORD` | Conexión SQL Server | ✅ Sí |
| `ADMIN_PASSWORD` / `USER_PASSWORD` | Contraseñas de seeds | Opcional |

> **IMPORTANTE**: La clave JWT nunca se escribe en el código fuente.  
> Se lee con `ENV.fetch("JWT_SECRET_KEY", "fallback_solo_dev")`.

---

## CRUD de colecciones

### Endpoints nuevos (Módulo 1)

| Método | Ruta | Descripción | Rol |
|---|---|---|---|
| GET | `/api/empleados?pagina=1&tamano=10&orden=apellido&dir=asc&buscar=gomez` | Listado paginado, filtrado y ordenado | Autenticado |
| GET | `/api/companias/:id/empleados?pagina=1&tamano=5` | Empleados de una compañía, paginados | Autenticado |
| POST | `/api/empleados/lote` | Creación masiva (bulk insert) | ADMIN/USUARIO |
| PATCH | `/api/empleados/:id` | Actualización parcial | ADMIN/USUARIO |
| DELETE | `/api/empleados/lote` | Eliminación múltiple | ADMIN |

### Paginación, filtrado y ordenamiento

**Parámetros de consulta:**
- `pagina` → número de página (mínimo 1)
- `tamano` → registros por página (1–100)
- `orden` → campo: `nombre`, `apellido`, `correo`, `cargo`, `salario`
- `dir` → `asc` | `desc`
- `buscar` → texto libre (filtra nombre, apellido o correo)

**Respuesta envolvente:**
```json
{
  "datos": [ { "id": 1, "nombre": "Carlos", ... } ],
  "pagina": 1,
  "tamano": 10,
  "total": 57,
  "totalPaginas": 6
}
```

**Implementación en Active Record** (`EmployeeRepository#get_paged`):
```ruby
scope = Employee.includes(:company)
scope = scope.where("nombre LIKE :t OR apellido LIKE :t OR correo LIKE :t", t: "%#{buscar}%")
scope = scope.order("#{col} #{direction}")  # col validado contra lista blanca
data  = scope.offset((pagina - 1) * tamano).limit(tamano)
```

### Creación masiva y eliminación múltiple

Ambas operaciones se ejecutan **dentro de una sola transacción del Unit of Work**: o se aplican todos los cambios, o ninguno.

```ruby
# EmployeeService#create_batch
@uow.transaction do |uow|
  employees_data.each do |data|
    emp = uow.employees.create_employee(data)
    uow.save(emp)
  end
end
```

---

## Programación asíncrona

### ¿Ruby on Rails soporta async nativo para acceso a datos?

**No de forma nativa en el stack clásico.** Active Record es sincrónico por diseño. Rails puede atender peticiones de forma concurrente (con Puma en modo multi-hilo), pero la sesión de base de datos bloquea el hilo mientras espera.

| Aspecto | Situación en Rails 8 |
|---|---|
| Peticiones HTTP | Concurrentes gracias a Puma (multi-thread) |
| Active Record | **Sincrónico** — bloquea el hilo en cada consulta |
| Async real para I/O | Requiere Async gem + Falcon, o migrar a Fiber-based DB adapters |

### Alternativa idiomática aplicada

**Active Job + Solid Queue** (incluido en este proyecto):

Para operaciones costosas (como bulk imports masivos o reportes), se delega a un background job:

```ruby
# app/jobs/bulk_employee_import_job.rb
class BulkEmployeeImportJob < ApplicationJob
  queue_as :default

  def perform(employees_data, company_id)
    EmployeeService.new.create_batch(
      employees_data.map { |d| d.merge(company_id: company_id) }
    )
  end
end

# Despacho desde el controlador (no bloquea el hilo de Puma):
BulkEmployeeImportJob.perform_later(employees_data, company_id)
```

**Equivalente a ASP.NET Core:** `IHostedService` / `BackgroundService` + `IBackgroundTaskQueue`.

### Conclusión técnica

Rails no ofrece `async/await` como Python-FastAPI o Node.js porque Active Record usa el pool de conexiones de ActiveRecord::ConnectionPool, que gestiona la concurrencia a nivel de hilo (no de corrutina). La alternativa idiomática y recomendada es **Active Job** para tareas pesadas y **Puma multi-thread** para concurrencia de peticiones.

---

## Validaciones

### Librería usada: Active Model Validations (nativa de Rails)

**Módulo 3** — Las validaciones viven en la **capa Application** (DTOs), no en el controlador.

```ruby
# app/dtos/employee_dto.rb
class EmployeeDto
  include ActiveModel::Validations

  validates :correo, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :salario, numericality: { greater_than: 0 }
  validate  :correo_debe_ser_unico  # regla de negocio
  
  def correo_debe_ser_unico
    errors.add(:correo, "ya está registrado") if Employee.exists?(correo: correo)
  end
end
```

### Reglas implementadas

| Entidad | Campo | Regla |
|---|---|---|
| Compañía | nombre | Obligatorio, 3–100 caracteres |
| Compañía | telefono | Obligatorio, solo dígitos, 7–15 caracteres |
| Empleado | nombre/apellido | Obligatorios |
| Empleado | correo | Obligatorio, formato válido, **único en BD** |
| Empleado | salario | Obligatorio, > 0 |
| Empleado | company_id | Obligatorio, compañía debe existir |

### Formato de error (422 Unprocessable Entity)

```json
{
  "mensaje": "Error de validación",
  "errores": [
    { "campo": "correo", "detalle": "no tiene formato de correo válido" },
    { "campo": "salario", "detalle": "debe ser mayor que 0" }
  ]
}
```

---

## Pruebas

### Framework: RSpec + FactoryBot + Faker

**Instalar y configurar:**
```bash
bundle install
bin/rails generate rspec:install
```

### Cómo ejecutar las pruebas

```bash
# Todas las pruebas
bundle exec rspec

# Alternativa en Windows si Bundler no encuentra el ejecutable:
C:\Users\DELL\.local\share\gem\ruby\4.0.0\bin\rspec.bat

# Solo unitarias
bundle exec rspec spec/services/

# Solo integración
bundle exec rspec spec/requests/

# Con formato documentado
bundle exec rspec --format documentation
```

### Qué se prueba

| Tipo | Archivo | Cobertura |
|---|---|---|
| Unitaria | `spec/services/company_service_spec.rb` | CRUD, rollback transaccional |
| Unitaria | `spec/services/employee_service_spec.rb` | Paginación, bulk, PATCH, rollback lote |
| Integración | `spec/requests/employees_spec.rb` | HTTP 200/201/400/401/403/422 |
| Integración | `spec/requests/auth_spec.rb` | Registro, login, perfil |

### Prueba del caso transaccional (rollback) — OBLIGATORIA

```ruby
it "hace rollback total si un empleado tiene datos inválidos" do
  company_data   = { nombre: "Empresa Rollback", ... }
  employees_data = [
    { correo: "juan@ok.com",       salario: 3000 },  # válido
    { correo: "correo-invalido",   salario: -500 }   # ← inválido → ROLLBACK
  ]

  expect {
    service.create_with_employees(company_data, employees_data)
  }.to raise_error(ActiveRecord::RecordInvalid)

  expect(Company.find_by(nombre: "Empresa Rollback")).to be_nil   # ← no guardó
  expect(Employee.find_by(correo: "juan@ok.com")).to be_nil        # ← rollback total
end
```

---

## Seguridad — JWT

### Autenticación con JWT (Módulo 5)

**Librería:** `jwt` gem (HS256) + `bcrypt` gem (has_secure_password)

**Flujo:**
```
POST /api/auth/registro  →  crea usuario (contraseña hasheada con bcrypt)
POST /api/auth/login     →  valida credenciales → emite JWT firmado
GET  /api/auth/perfil    →  requiere Bearer token

Cada petición protegida:
  Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
  → middleware verifica firma + expiración
  → @current_user disponible en controladores
```

**Payload del JWT:**
```json
{
  "sub": 1,
  "correo": "admin@api.com",
  "rol": "ADMIN",
  "company_id": null,
  "exp": 1735689600,
  "iat": 1735603200
}
```

### Autorización por roles (Módulo 5)

| Operación | Rol requerido |
|---|---|
| GET (listar / consultar) | Cualquier usuario autenticado |
| POST / PUT (crear / actualizar) | ADMIN o USUARIO |
| DELETE (eliminar) | Solo ADMIN |
| POST /api/companias/con_empleados | Solo ADMIN |

**Implementación:**
```ruby
# En cada controlador:
before_action :authenticate_request!

def destroy
  authorize_roles!("ADMIN")   # → 403 si no es ADMIN
  @service.delete(params[:id])
  head :no_content
end
```

### Autorización por políticas — Módulo 6

**Equivalencia con ASP.NET Core:**

| ASP.NET Core | Ruby on Rails |
|---|---|
| `AddAuthorization(o => o.AddPolicy(...))` | Método `authorize_ownership!` en ApplicationController |
| `IAuthorizationHandler` | Lógica en `authorize_ownership!` que evalúa claims vs recurso |
| `[Authorize(Policy = "EsPropietario")]` | `before_action` o llamada explícita en acción |
| `ClaimsPrincipal` | `@current_payload` (hash del JWT decodificado) |

**Política implementada — `EsPropietarioDeCompania`:**
```ruby
# ApplicationController
def authorize_ownership!(employee_id)
  return if current_user.admin?  # ADMIN exento

  employee = Employee.find(employee_id)
  unless current_user.company_id == employee.company_id
    raise AuthorizationError,
          "Solo puede modificar empleados de su propia compañía"
  end
end
```

**Política — `LimiteSalario`:**
```ruby
SALARY_LIMIT = 50_000

def authorize_salary_limit!(salario)
  return if current_user.admin?
  if salario.to_f > SALARY_LIMIT
    raise AuthorizationError, "Solo ADMIN puede asignar salarios > #{SALARY_LIMIT}"
  end
end
```

**Prueba de políticas:**
- USUARIO puede editar empleados de SU compañía → `200 OK`
- USUARIO intenta editar empleado de otra compañía → `403 Forbidden`
- ADMIN puede editar cualquier empleado → `200 OK`

---

## Comparación con ASP.NET Core

| Concepto en ASP.NET Core | Equivalente en Ruby on Rails |
|---|---|
| `IEnumerable<T>` / `List<T>` | `ActiveRecord::Relation` (lazy) / `.to_a` |
| `Skip(n).Take(m)` | `.offset(n).limit(m)` |
| `async/await` + `Task<T>` | **No nativo en AR** — Puma multi-hilo + Active Job para background |
| `DataAnnotations` / `FluentValidation` | `Active Model Validations` (nativo) en DTOs |
| `xUnit` / `NUnit` + `Moq` | `RSpec` + `FactoryBot` + dobles de RSpec |
| `AddAuthentication().AddJwtBearer()` | gem `jwt` + `AuthService.decode_token` en ApplicationController |
| `[Authorize(Roles = "ADMIN")]` | `authorize_roles!("ADMIN")` — método helper en ApplicationController |
| `[Authorize(Policy = "...")]` + `IAuthorizationHandler` | `authorize_ownership!` / `authorize_salary_limit!` — métodos de política en ApplicationController |
| `ClaimsPrincipal` / `Claims` | `@current_payload` (HashWithIndifferentAccess del JWT decodificado) |
| `has_secure_password` (BCrypt) | `has_secure_password` nativo de Rails (también usa BCrypt) |

---

## Conclusiones Parte II

1. **CRUD de colecciones:** Active Record hace trivial la paginación con `.offset.limit`; el Unit of Work garantiza atomicidad en operaciones masivas.

2. **Asincronía:** Rails/Active Record no ofrece `async/await` real para I/O de BD. La alternativa idiomática y robusta es **Active Job + Solid Queue**, que desacopla el trabajo pesado del hilo HTTP sin cambiar la arquitectura Onion.

3. **Validaciones:** `Active Model Validations` en los DTOs mantiene las reglas en la capa Application, separadas del ORM y del controlador.

4. **Pruebas:** RSpec + FactoryBot es el estándar del ecosistema Ruby. `use_transactional_fixtures: true` garantiza aislamiento entre tests sin limpiar manualmente la BD.

5. **JWT:** La gem `jwt` con HS256 y `has_secure_password` (bcrypt) cubren autenticación y hashing de forma segura. La clave secreta siempre se lee de variables de entorno.

6. **Políticas:** Los métodos `authorize_ownership!` y `authorize_salary_limit!` replican el patrón `IAuthorizationHandler` de ASP.NET Core evaluando claims del token contra atributos del recurso solicitado en tiempo de petición.
