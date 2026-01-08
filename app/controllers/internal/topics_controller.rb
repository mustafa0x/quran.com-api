# frozen_string_literal: true

module Internal
  class TopicsController < ApplicationController
    before_action :authorize_admin_token

    def sync
      payload = sync_params
      topics_payload = payload[:topics] || []
      delete_ids = payload[:delete_ids] || []

      result = Internal::TopicsSync.call(topics: topics_payload, delete_ids: delete_ids)

      status = result[:errors].any? ? :unprocessable_entity : :ok
      render json: result, status: status
    end

    private

    def authorize_admin_token
      expected = ENV['ADMIN_TOKEN'].to_s
      provided = request.headers['a_t_h'].to_s
      return if expected.present? && provided.present? &&
        ActiveSupport::SecurityUtils.secure_compare(provided, expected)

      render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    def sync_params
      params.permit(
        delete_ids: [],
        topics: [
          :id,
          :name,
          :arabic_name,
          :description,
          :ayah_range,
          :wikipedia_link,
          :ontology,
          :thematic,
          :depth,
          :parent_id,
          :ontology_parent_id,
          :thematic_parent_id,
          :resource_content_id
        ]
      )
    end
  end
end
