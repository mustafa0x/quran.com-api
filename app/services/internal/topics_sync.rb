# frozen_string_literal: true

module Internal
  class TopicsSync
    def self.call(topic:, delete_id: nil)
      new(topic: topic, delete_id: delete_id).call
    end

    def initialize(topic:, delete_id:)
      @topic = topic
      @delete_id = delete_id
    end

    def call
      result = { upserted: 0, deleted: 0, errors: [] }

      Topic.transaction do
        if topic.blank? && delete_id.blank?
          result[:errors] << { id: nil, error: 'topic or delete_id is required' }
          return rollback!(result)
        end

        if delete_id.present?
          delete_id_int = normalize_id(delete_id)
          if delete_id_int.nil?
            result[:errors] << { id: delete_id, error: 'delete_id must be an integer' }
            return rollback!(result)
          end

          result[:deleted] = Topic.where(id: delete_id_int).delete_all
        end

        if topic.present?
          attrs = topic.dup
          topic_id = attrs.delete(:id)

          if topic_id.blank?
            result[:errors] << { id: nil, error: 'id is required' }
            return rollback!(result)
          end

          topic_id_int = normalize_id(topic_id)
          if topic_id_int.nil?
            result[:errors] << { id: topic_id, error: 'id must be an integer' }
            return rollback!(result)
          end

          record = Topic.where(id: topic_id_int).first_or_initialize
          record.assign_attributes(attrs)

          if record.save
            result[:upserted] = 1
          else
            result[:errors] << { id: topic_id_int, error: record.errors.full_messages.join(', ') }
            return rollback!(result)
          end
        end
      end

      result
    end

    private

    attr_reader :topic, :delete_id

    def normalize_id(value)
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def rollback!(result)
      result[:upserted] = 0
      result[:deleted] = 0
      raise ActiveRecord::Rollback
    end
  end
end
