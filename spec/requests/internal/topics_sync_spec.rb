# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal Topics sync', type: :request do
  let(:admin_token) { 'test-admin-token' }
  let(:headers) { { 'a_t_h' => admin_token } }

  def build_topic_id(offset = 0)
    Topic.maximum(:id).to_i + 1000 + offset
  end

  around do |example|
    original = ENV['ADMIN_TOKEN']
    ENV['ADMIN_TOKEN'] = admin_token
    example.run
    ENV['ADMIN_TOKEN'] = original
  end

  it 'rejects requests without the admin token' do
    post '/internal/topics/sync', params: { topic: { id: 1, slug: 'test', name: 'Test' } }

    expect(response).to have_http_status(:unauthorized)
    json = JSON.parse(response.body)
    expect(json['error']).to eq('Unauthorized')
  end

  it 'upserts topics by id' do
    topic_id = build_topic_id
    payload = {
      topic: {
        id: topic_id,
        slug: 'creation',
        name: 'Creation',
        arabic_name: 'al-khalq',
        description: 'Topic description',
        ontology: true,
        depth: 0
      }
    }

    post '/internal/topics/sync', params: payload, headers: headers

    expect(response).to have_http_status(:ok)
    topic = Topic.find(topic_id)
    expect(topic.name).to eq('Creation')
    expect(topic.arabic_name).to eq('al-khalq')
    expect(topic.slug).to eq('creation')
    json = JSON.parse(response.body)
    expect(json['upserted']).to eq(1)
  end

  it 'updates existing topics' do
    topic_id = build_topic_id
    Topic.create!(id: topic_id, name: 'Old Name', slug: 'old-name')

    post '/internal/topics/sync',
      params: { topic: { id: topic_id, slug: 'old-name', name: 'New Name' } },
      headers: headers

    expect(response).to have_http_status(:ok)
    expect(Topic.find(topic_id).name).to eq('New Name')
  end

  it 'deletes topics by id' do
    topic_id = build_topic_id
    Topic.create!(id: topic_id, name: 'Delete Me', slug: 'delete-me')

    post '/internal/topics/sync',
      params: { delete_id: topic_id },
      headers: headers

    expect(response).to have_http_status(:ok)
    expect(Topic.where(id: topic_id)).to be_empty
  end

  it 'rejects batch payloads' do
    post '/internal/topics/sync',
      params: { topics: [{ id: 1, slug: 'topic-1', name: 'Batch' }] },
      headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    json = JSON.parse(response.body)
    expect(json['errors'].first['error']).to eq('Batch payloads are not supported')
  end

  it 'rejects missing slug' do
    topic_id = build_topic_id
    post '/internal/topics/sync',
      params: { topic: { id: topic_id, name: 'Missing slug' } },
      headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(Topic.where(id: topic_id)).to be_empty
  end
end
