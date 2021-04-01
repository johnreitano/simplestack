module TodoItemHelper
  def list_completion_percent
    if list_size.zero?
      0.0
    else
      (100 * list_completed_count.to_f / list_size).round(1)
    end
  end

  def list_size
    TodoList.first_or_create.todo_items.count
  end

  def list_completed_count
    TodoList.first_or_create.todo_items.completed.count
  end
end
