class TodoItem
  include Mongoid::Document
  include Mongoid::Timestamps
  belongs_to :todo_list

  field :title, type: String
  field :url, type: String
  field :content, type: String
  field :completed, type: Boolean, default: FALSE
  field :order, type: Integer

end