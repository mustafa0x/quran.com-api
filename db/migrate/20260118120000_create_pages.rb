# frozen_string_literal: true

class CreatePages < ActiveRecord::Migration[7.0]
  def change
    create_table :pages do |t|
      t.bigint :parent_id
      t.integer :ord, null: false, default: 0
      t.boolean :hidden, null: false, default: false
      t.string :slug, null: false
      t.string :title, null: false
      t.jsonb :headings, null: false, default: []
      t.text :text
      t.text :description
      t.string :lang, null: false, default: 'en'
      t.string :image
      t.string :thumbnail

      t.timestamps
    end

    add_index :pages, :parent_id
    add_index :pages, [:lang, :slug], unique: true

    add_foreign_key :pages, :pages, column: :parent_id
  end
end
