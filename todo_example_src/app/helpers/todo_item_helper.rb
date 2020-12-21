module TodoItemHelper
  def list_completion_percent
    if list_size.zero?
      0.0
    else
      (100 * list_completed_count.to_f / list_size).round(1)
    end
  end

  def list_size
    TodoItem.count
  end

  def list_completed_count
    TodoItem.completed.count
  end

  def list_completion_status
    if list_completion_percent == 0
      'Not started'
    elsif list_completion_percent == 100
      'All Done'
    else
      'In Progress'
    end
  end
end
