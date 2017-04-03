require 'rails_helper'

module Api
  module V1
    RSpec.describe TodoListsController do
      describe 'get index' do

        it 'assigns @todo_list' do
          todo_list = create(:todo_list)
          get :index
          expect(assigns(:todo_list)).to eq([todo_list])
        end

        it 'has a 200 status code' do
          get :index
          expect(response.status).to eq(200)
        end

        it 'returns json' do
          get :index
          expect(response.content_type).to eq 'application/vnd.api+json'
        end
      end

      describe 'create list' do
        let(:params) {
          {
              data: {
                   attributes: {
                       title: 'Fuzz',
                       description: 'Bar'
                   },
                   type: 'todo-lists'
               }
          }
        }

        it 'has a 201 status code' do
          post :create, params: params, format: :json
          expect(response.status).to eq(201)
        end

        it 'stored the todo_list' do
          expect{ post :create, params: params, format: :json }.
              to change{ TodoList.count }.by(1)
        end
      end

      describe 'delete list' do
        before(:each) do
          @todo_list = create(:todo_list)
        end

        it 'it should remove the list' do
          expect{ delete :destroy, params: { id: @todo_list.id } }.
              to change{ TodoList.count }.by(-1)
        end
      end
    end
  end
end