class TodoItem < ApplicationRecord
  belongs_to :todo_list
  scope :completed, -> { where.not(completed_at: nil) }
  validates :description, presence: true
  
  def completed?
    completed_at.present?
  end
end
