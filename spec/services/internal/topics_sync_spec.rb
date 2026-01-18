# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::TopicsSync do
  def build_topic_id(offset = 0)
    Topic.maximum(:id).to_i + 1000 + offset
  end

  it 'upserts a topic and deletes by id' do
    base_id = build_topic_id
    Topic.create!(id: base_id, name: 'Old Name', slug: 'old-name')
    Topic.create!(id: base_id + 2, name: 'Delete Me', slug: 'delete-me')

    result = described_class.call(
      topic: { id: base_id, name: 'New Name', slug: 'new-name' },
      delete_id: base_id + 2
    )

    expect(result[:upserted]).to eq(1)
    expect(result[:deleted]).to eq(1)
    expect(result[:errors]).to be_empty
    expect(Topic.find(base_id).name).to eq('New Name')
    expect(Topic.where(id: base_id + 2)).to be_empty
  end

  it 'rolls back when validation fails' do
    base_id = build_topic_id
    delete_id = base_id + 1
    Topic.create!(id: delete_id, name: 'Delete Me', slug: 'delete-me')

    result = described_class.call(
      topic: { id: base_id, name: 'Missing slug' },
      delete_id: delete_id
    )

    expect(result[:upserted]).to eq(0)
    expect(result[:deleted]).to eq(0)
    expect(result[:errors]).not_to be_empty
    expect(Topic.where(id: delete_id)).not_to be_empty
    expect(Topic.where(id: base_id)).to be_empty
  end

  it 'collects errors when topic id is missing' do
    result = described_class.call(topic: { name: 'Missing id', slug: 'missing-id' }, delete_id: nil)

    expect(result[:upserted]).to eq(0)
    expect(result[:errors]).to eq([{ id: nil, error: 'id is required' }])
  end

  it 'collects errors when topic id is not an integer' do
    result = described_class.call(topic: { id: 'abc', name: 'Bad id', slug: 'bad-id' }, delete_id: nil)

    expect(result[:upserted]).to eq(0)
    expect(result[:errors]).to eq([{ id: 'abc', error: 'id must be an integer' }])
  end
end
