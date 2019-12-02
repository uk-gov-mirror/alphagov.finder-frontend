class Score < ApplicationRecord
  belongs_to :judgement_set
  validates :link, :judgement, :link_position, presence: true
end
