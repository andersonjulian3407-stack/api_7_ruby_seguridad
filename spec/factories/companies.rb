FactoryBot.define do
  factory :company do
    nombre    { Faker::Company.name.truncate(80) }
    direccion { Faker::Address.full_address.truncate(200) }
    telefono  { Faker::Number.number(digits: 10).to_s }
  end
end
