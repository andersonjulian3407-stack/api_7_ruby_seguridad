FactoryBot.define do
  factory :employee do
    nombre   { Faker::Name.first_name }
    apellido { Faker::Name.last_name }
    correo   { Faker::Internet.unique.email }
    cargo    { Faker::Job.title }
    salario  { Faker::Number.decimal(l_digits: 4, r_digits: 2) }
    association :company
  end
end
