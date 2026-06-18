class EmailSummary < ApplicationRecord
  belongs_to :email_thread,
             foreign_key: :thread_id
end
