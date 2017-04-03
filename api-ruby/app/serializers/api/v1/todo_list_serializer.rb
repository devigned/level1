class Api::V1::TodoListSerializer < Api::V1::ApplicationSerializer
  attributes :id, :title, :description
  has_many :todo_items
end