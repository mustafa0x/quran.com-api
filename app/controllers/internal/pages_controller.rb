# frozen_string_literal: true

module Internal
  class PagesController < ApplicationController
    before_action :authorize_admin_token

    def sync
      if params[:pages].present? || params[:delete_ids].present? ||
        params[:page].is_a?(Array) || params[:delete_id].is_a?(Array)
        return render json: { upserted: 0, deleted: 0,
                              errors: [{ id: nil, error: 'Batch payloads are not supported' }] },
                      status: :unprocessable_entity
      end

      page_attrs = params[:page].present? ? page_params.to_h : nil
      delete_id = params[:delete_id]

      result = Internal::PagesSync.call(page: page_attrs, delete_id: delete_id)

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

    def page_params
      params.require(:page).permit(
        :id,
        :parent_id,
        :parent,
        :ord,
        :hidden,
        :slug,
        :title,
        :text,
        :description,
        :lang,
        :image,
        :thumbnail,
        headings: []
      )
    end
  end
end