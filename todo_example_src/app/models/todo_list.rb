    class TodoList < ApplicationRecord
      has_many :todo_items

      before_validation :set_deadline, if: -> { deadline.blank? }

      def postpone!
        update(deadline: deadline.next_day)
      end

      private

      def set_deadline
        self.deadline = Time.now.next_day
      end
    end
