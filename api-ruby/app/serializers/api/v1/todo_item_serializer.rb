class Api::V1::TodoItemSerializer < Api::V1::ApplicationSerializer
  attributes :id, :title, :url, :content, :completed, :order
  has_one :todo_list
end