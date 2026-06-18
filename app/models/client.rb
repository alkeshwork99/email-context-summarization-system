class Client < ApplicationRecord
  belongs_to :firm

  has_many :email_threads,
           dependent: :destroy

  has_one :client_summary,
          dependent: :destroy
end
