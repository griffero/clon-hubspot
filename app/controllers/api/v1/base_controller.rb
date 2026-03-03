module Api
  module V1
    class BaseController < ApplicationController
      include Pagy::Method

      protect_from_forgery with: :null_session

      rescue_from ActiveRecord::RecordNotFound, with: :not_found

      private

      def not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def pagy_metadata(pagy)
        {
          page: pagy.page,
          items: pagy.limit,
          count: pagy.count,
          pages: pagy.pages
        }
      end
    end
  end
end
