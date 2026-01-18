# frozen_string_literal: true

class AddSlugToTopics < ActiveRecord::Migration[7.0]
  class MigrationTopic < ApplicationRecord
    self.table_name = "topics"
  end

  def up
    add_column :topics, :slug, :string

    MigrationTopic.reset_column_information

    say_with_time "Backfilling topic slugs" do
      MigrationTopic.find_each do |topic|
        next if topic.slug.present?

        base = topic.name.to_s.parameterize
        base = "topic-#{topic.id}" if base.blank?

        slug = base
        counter = 2
        while MigrationTopic.exists?(slug: slug)
          slug = "#{base}-#{counter}"
          counter += 1
        end

        topic.update_columns(slug: slug)
      end
    end

    change_column_null :topics, :slug, false
    add_index :topics, :slug, unique: true
  end

  def down
    remove_index :topics, :slug
    remove_column :topics, :slug
  end
end
