
FactoryGirl.define do
  factory :todo_list do
    title 'test todo list'
    description 'super duper test todo list'
  end

  factory :todo_item do
    title 'my item'
    url 'http://microsoft.com'
    content 'test content'
    completed false
    order 1
  end
end