class CreateTodoItems < ActiveRecord::Migration[6.0]
  def change
    create_table :todo_items do |t|
      t.references :todo_list, null: false, foreign_key: true
      t.text :description
      t.datetime :completed_at

      t.timestamps
    end
  end
end
