class TodoListsController < ApplicationController
  def postpone
    @todo_list = TodoList.find(params[:id])
    @todo_list.postpone!
    redirect_to todo_items_path, notice: 'Todo List deadline postponed.'
  end
end
