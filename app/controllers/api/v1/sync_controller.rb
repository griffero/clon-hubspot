module Api
  module V1
    class SyncController < BaseController
      def create
        HubspotSyncJob.perform_later
        render json: { message: "Sync started" }, status: :accepted
      end
    end
  end
end
