# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::TopicsSync do
  def build_topic_id(offset = 0)
    Topic.maximum(:id).to_i + 1000 + offset
  end

  it 'upserts topics and deletes by id' do
    base_id = build_topic_id
    Topic.create!(id: base_id, name: 'Old Name')
    Topic.create!(id: base_id + 2, name: 'Delete Me')

    result = described_class.call(
      topics: [
        { id: base_id, name: 'New Name' },
        { id: base_id + 1, name: 'Second Topic' }
      ],
      delete_ids: [base_id + 2]
    )

    expect(result[:upserted]).to eq(2)
    expect(result[:deleted]).to eq(1)
    expect(result[:errors]).to be_empty
    expect(Topic.find(base_id).name).to eq('New Name')
    expect(Topic.find(base_id + 1).name).to eq('Second Topic')
    expect(Topic.where(id: base_id + 2)).to be_empty
  end

  it 'collects errors when topic id is missing' do
    result = described_class.call(topics: [{ name: 'Missing id' }], delete_ids: [])

    expect(result[:upserted]).to eq(0)
    expect(result[:errors]).to eq([{ id: nil, error: 'id is required' }])
  end
end
