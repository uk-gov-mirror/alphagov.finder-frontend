class JudgementSet < ApplicationRecord
  has_many :scores
  validates_presence_of :scores
end
