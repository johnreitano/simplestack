class CreateTodoLists < ActiveRecord::Migration[6.0]
  def change
    create_table :todo_lists do |t|
      t.datetime :deadline

      t.timestamps
    end
  end
end
