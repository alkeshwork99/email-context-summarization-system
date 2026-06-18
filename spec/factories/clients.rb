FactoryBot.define do
  factory :client do
    firm
    name   { Faker::Name.name }
    email  { Faker::Internet.unique.email }
    phone  { Faker::PhoneNumber.phone_number }
    status { "active" }
  end
end
