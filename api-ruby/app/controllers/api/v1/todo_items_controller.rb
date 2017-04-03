module Api
  module V1
    class TodoItemsController < ApplicationController
      before_action :set_todo_list, except: [:show, :destroy]
      before_action :set_todo_item, except: [:create]

      def create
        render json: @todo_list.todo_items.create(item_params.slice(:content)), status: :created
      end

      def show
        render json: @todo_item
      end

      def destroy
        if @todo_item.destroy
          render json: nil, status: 204
        else
          render json: @todo_item.errors, status: 400
        end
      end

      def update
        if @todo_item.update(item_params.except(:list_id))
          render json: @todo_item, status: :ok
        else
          render json: @todo_item, status: :unprocessable_entity
        end
      end

      private

      def set_todo_list
        @todo_list = TodoList.find(todo_list_id)
      end

      def set_todo_item
        @todo_item = TodoItem.find(params[:id])
      end

      def item_params
        ActiveModelSerializers::Deserialization.jsonapi_parse!(params)
      end

      def todo_list_id
        # idk ¯\_(ツ)_/¯ the tests fail b/c of AMS resource serialization, so just looks here if not found
        item_params[:todo_list_id] || params['data']['relationships']['todo-list']['data']
      end
    end
  end
end
