FactoryBot.define do
  factory :accountant do
    firm
    name      { Faker::Name.name }
    email     { Faker::Internet.unique.email }
    password  { "password123" }
    role      { "accountant" }
    is_active { true }

    trait :admin do
      role { "admin" }
    end

    trait :superuser do
      role { "superuser" }
    end
  end
end
