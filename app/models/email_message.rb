class EmailMessage < ApplicationRecord
  belongs_to :email_thread,
             foreign_key: :thread_id

  belongs_to :accountant,
             optional: true
end
