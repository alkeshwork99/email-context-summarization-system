class Firm < ApplicationRecord
  has_many :accountants,
           dependent: :destroy

  has_many :clients,
           dependent: :destroy
end
