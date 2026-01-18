# frozen_string_literal: true

module Api::V4
  class TopicsController < ApiController
    def index
      @topics = Topic.order(:id)
      render
    end

    def show
      @topic = Topic.find_by(id: params[:id])

      if @topic
        render
      else
        render_404("Topic not found")
      end
    end
  end
end
