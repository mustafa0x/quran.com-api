# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal Pages sync', type: :request do
  let(:admin_token) { 'test-admin-token' }
  let(:headers) { { 'a_t_h' => admin_token } }

  def build_page_id(offset = 0)
    Page.maximum(:id).to_i + 1000 + offset
  end

  around do |example|
    original = ENV['ADMIN_TOKEN']
    ENV['ADMIN_TOKEN'] = admin_token
    example.run
    ENV['ADMIN_TOKEN'] = original
  end

  it 'rejects requests without the admin token' do
    post '/internal/pages/sync', params: { page: { id: 1, slug: 'test', title: 'Test', lang: 'en' } }

    expect(response).to have_http_status(:unauthorized)
    json = JSON.parse(response.body)
    expect(json['error']).to eq('Unauthorized')
  end

  it 'upserts pages by id' do
    page_id = build_page_id
    payload = {
      page: {
        id: page_id,
        slug: 'introduction',
        title: 'Introduction',
        lang: 'en',
        ord: 1,
        headings: ['What is the Quran?'],
        text: 'Page content',
        description: 'Page description'
      }
    }

    post '/internal/pages/sync', params: payload, headers: headers

    expect(response).to have_http_status(:ok)
    page = Page.find(page_id)
    expect(page.slug).to eq('introduction')
    expect(page.title).to eq('Introduction')
    expect(page.lang).to eq('en')
    json = JSON.parse(response.body)
    expect(json['upserted']).to eq(1)
  end

  it 'updates existing pages' do
    page_id = build_page_id
    Page.create!(id: page_id, slug: 'intro', title: 'Old title', lang: 'en')

    post '/internal/pages/sync',
         params: { page: { id: page_id, slug: 'intro', title: 'New title', lang: 'en' } },
         headers: headers

    expect(response).to have_http_status(:ok)
    expect(Page.find(page_id).title).to eq('New title')
  end

  it 'deletes pages by id' do
    page_id = build_page_id
    Page.create!(id: page_id, slug: 'delete-me', title: 'Delete me', lang: 'en')

    post '/internal/pages/sync',
         params: { delete_id: page_id },
         headers: headers

    expect(response).to have_http_status(:ok)
    expect(Page.where(id: page_id)).to be_empty
  end

  it 'rejects batch payloads' do
    post '/internal/pages/sync',
         params: { pages: [{ id: 1, slug: 'page-1', title: 'Batch', lang: 'en' }] },
         headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    json = JSON.parse(response.body)
    expect(json['errors'].first['error']).to eq('Batch payloads are not supported')
  end

  it 'rejects missing slug' do
    page_id = build_page_id

    post '/internal/pages/sync',
         params: { page: { id: page_id, title: 'Missing slug', lang: 'en' } },
         headers: headers

    expect(response).to have_http_status(:unprocessable_entity)
    expect(Page.where(id: page_id)).to be_empty
  end

  it 'accepts parent alias' do
    parent_id = build_page_id
    child_id = parent_id + 1

    Page.create!(id: parent_id, slug: 'parent', title: 'Parent', lang: 'en')

    post '/internal/pages/sync',
         params: { page: { id: child_id, parent: parent_id, slug: 'child', title: 'Child', lang: 'en' } },
         headers: headers

    expect(response).to have_http_status(:ok)
    expect(Page.find(child_id).parent_id).to eq(parent_id)
  end
end
