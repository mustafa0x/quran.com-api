# frozen_string_literal: true

module Internal
  class TopicsController < ApplicationController
    before_action :authorize_admin_token

    def sync
      if params[:topics].present? || params[:delete_ids].present? ||
        params[:topic].is_a?(Array) || params[:delete_id].is_a?(Array)
        return render json: { upserted: 0, deleted: 0,
                              errors: [{ id: nil, error: 'Batch payloads are not supported' }] },
                      status: :unprocessable_entity
      end

      topic_attrs = params[:topic].present? ? topic_params.to_h : nil
      delete_id = params[:delete_id]

      result = Internal::TopicsSync.call(topic: topic_attrs, delete_id: delete_id)

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

    def topic_params
      params.require(:topic).permit(
        :id,
        :slug,
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
      )
    end
  end
end
