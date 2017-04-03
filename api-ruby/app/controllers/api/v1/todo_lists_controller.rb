module Api
  module V1
    class TodoListsController < ApplicationController
      before_action :set_todo_list, only: [:show, :update, :destroy]

      def index
        @todo_list = TodoList.all
        render json: @todo_list
      end

      def show
        render json: @todo_list
      end

      def create
        @todo_list = TodoList.new(list_params)
        if @todo_list.save
          render json: @todo_list, status: :created
        else
          render json: @todo_list, status: :unprocessable_entity
        end
      end

      def update
        if @todo_list.update(list_params)
          render json: @todo_list, status: :ok
        else
          render json: @todo_list, status: :unprocessable_entity
        end
      end

      def destroy
        @todo_list.destroy
        render json: nil, status: :no_content
      end

      private

      def list_params
        ActiveModelSerializers::Deserialization.jsonapi_parse!(params)
      end

      def set_todo_list
        @todo_list = TodoList.find(params[:id])
      end

    end
  end
end
