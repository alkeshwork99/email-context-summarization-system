class Accountant < ApplicationRecord
  belongs_to :firm

  has_many :email_messages,
           dependent: :nullify

  has_secure_password

  def admin?
    role == "admin"
  end

  def superuser?
    role == "superuser"
  end

  def accountant?
    role == "accountant"
  end
end
