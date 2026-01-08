# frozen_string_literal: true

module Internal
  class TopicsSync
    def self.call(topics:, delete_ids:)
      new(topics: topics, delete_ids: delete_ids).call
    end

    def initialize(topics:, delete_ids:)
      @topics = topics
      @delete_ids = delete_ids
    end

    def call
      result = { upserted: 0, deleted: 0, errors: [] }

      Topic.transaction do
        delete_ids.each do |topic_id|
          result[:deleted] += Topic.where(id: topic_id).delete_all
        end

        topics.each do |attrs|
          topic_id = attrs.delete(:id)
          if topic_id.blank?
            result[:errors] << { id: nil, error: 'id is required' }
            next
          end

          topic = Topic.where(id: topic_id).first_or_initialize
          topic.assign_attributes(attrs)

          if topic.save
            result[:upserted] += 1
          else
            result[:errors] << { id: topic_id, error: topic.errors.full_messages.join(', ') }
          end
        end
      end

      result
    end

    private

    attr_reader :topics, :delete_ids
  end
end
