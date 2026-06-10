FactoryBot.define do
  factory :user do
    nombre   { Faker::Name.first_name }
    correo   { Faker::Internet.unique.email }
    password { "password123" }

    # Por defecto crea el rol USUARIO si existe, si no lo crea
    after(:create) do |user|
      usuario_role = Role.find_or_create_by!(nombre: "USUARIO")
      user.roles << usuario_role unless user.roles.include?(usuario_role)
    end

    trait :admin do
      after(:create) do |user|
        # Quitar rol USUARIO si se agregó por el bloque base y asignar ADMIN
        usuario_role = Role.find_or_create_by!(nombre: "USUARIO")
        admin_role   = Role.find_or_create_by!(nombre: "ADMIN")
        user.roles.delete(usuario_role)
        user.roles << admin_role unless user.roles.include?(admin_role)
      end
    end

    trait :admin_bogota do
      after(:create) do |user|
        usuario_role = Role.find_or_create_by!(nombre: "USUARIO")
        admin_role   = Role.find_or_create_by!(nombre: "ADMIN")
        user.roles.delete(usuario_role)
        user.roles << admin_role unless user.roles.include?(admin_role)
        user.user_claims.find_or_create_by!(claim_type: "ciudad", claim_value: "Bogota")
      end
    end

    trait :admin_medellin do
      after(:create) do |user|
        usuario_role = Role.find_or_create_by!(nombre: "USUARIO")
        admin_role   = Role.find_or_create_by!(nombre: "ADMIN")
        user.roles.delete(usuario_role)
        user.roles << admin_role unless user.roles.include?(admin_role)
        user.user_claims.find_or_create_by!(claim_type: "ciudad", claim_value: "Medellin")
      end
    end
  end
end
