class TodoItem < ApplicationRecord
  belongs_to :todo_list
  scope :completed, -> { where.not(completed_at: nil) }
  validates :description, presence: true
  after_create_commit { broadcast_prepend_to 'todo_items' }
  after_update_commit { broadcast_replace_to 'todo_items' }
  after_destroy_commit { broadcast_remove_to 'todo_items' }

  def completed?
    completed_at.present?
  end

  def toggle_complete!
    update!(completed_at: completed_at ? nil : Time.now)
  end
end
