FactoryBot.define do
  factory :firm do
    name   { Faker::Company.name }
    domain { Faker::Internet.unique.domain_name }
  end
end
