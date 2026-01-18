# frozen_string_literal: true

module Internal
  class PagesSync
    def self.call(page:, delete_id: nil)
      new(page: page, delete_id: delete_id).call
    end

    def initialize(page:, delete_id:)
      @page = page
      @delete_id = delete_id
    end

    def call
      result = { upserted: 0, deleted: 0, errors: [] }

      Page.transaction do
        if page.blank? && delete_id.blank?
          result[:errors] << { id: nil, error: 'page or delete_id is required' }
          return rollback!(result)
        end

        if delete_id.present?
          delete_id_int = normalize_id(delete_id)
          if delete_id_int.nil?
            result[:errors] << { id: delete_id, error: 'delete_id must be an integer' }
            return rollback!(result)
          end

          result[:deleted] = Page.where(id: delete_id_int).delete_all
        end

        if page.present?
          attrs = normalize_attrs(page.dup)
          page_id = attrs.delete(:id) || attrs.delete('id')

          if page_id.blank?
            result[:errors] << { id: nil, error: 'id is required' }
            return rollback!(result)
          end

          page_id_int = normalize_id(page_id)
          if page_id_int.nil?
            result[:errors] << { id: page_id, error: 'id must be an integer' }
            return rollback!(result)
          end

          record = Page.where(id: page_id_int).first_or_initialize
          record.assign_attributes(attrs)

          if record.save
            result[:upserted] = 1
          else
            result[:errors] << { id: page_id_int, error: record.errors.full_messages.join(', ') }
            return rollback!(result)
          end
        end
      end

      result
    end

    private

    attr_reader :page, :delete_id

    def normalize_id(value)
      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def normalize_attrs(attrs)
      # Support `parent` as an alias for `parent_id`.
      if attrs.key?(:parent) && attrs[:parent_id].blank?
        attrs[:parent_id] = attrs[:parent]
      end

      if attrs.key?('parent') && (attrs['parent_id'].blank? || attrs['parent_id'].nil?)
        attrs['parent_id'] = attrs['parent']
      end

      attrs.delete(:parent)
      attrs.delete('parent')
      attrs
    end

    def rollback!(result)
      result[:upserted] = 0
      result[:deleted] = 0
      raise ActiveRecord::Rollback
    end
  end
end
