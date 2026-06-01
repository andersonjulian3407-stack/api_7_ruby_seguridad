FactoryBot.define do
  factory :user do
    nombre   { Faker::Name.first_name }
    correo   { Faker::Internet.unique.email }
    password { "password123" }
    rol      { "USUARIO" }

    trait :admin do
      rol { "ADMIN" }
    end
  end
end
