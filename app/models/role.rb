class Role < ApplicationRecord
  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles
  has_many :role_claims, dependent: :destroy

  validates :nombre, presence: true, uniqueness: true
end
