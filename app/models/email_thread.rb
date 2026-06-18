class EmailThread < ApplicationRecord
  belongs_to :client

  has_many :email_messages,
           foreign_key: :thread_id,
           dependent: :destroy

  has_one :email_summary,
          foreign_key: :thread_id,
          dependent: :destroy
end
