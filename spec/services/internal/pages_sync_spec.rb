# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::PagesSync do
  def build_page_id(offset = 0)
    Page.maximum(:id).to_i + 1000 + offset
  end

  it 'upserts a page and deletes by id' do
    base_id = build_page_id
    Page.create!(id: base_id, slug: 'old-slug', title: 'Old title', lang: 'en')
    Page.create!(id: base_id + 2, slug: 'delete-me', title: 'Delete me', lang: 'en')

    result = described_class.call(
      page: { id: base_id, slug: 'new-slug', title: 'New title', lang: 'en' },
      delete_id: base_id + 2
    )

    expect(result[:upserted]).to eq(1)
    expect(result[:deleted]).to eq(1)
    expect(result[:errors]).to be_empty
    expect(Page.find(base_id).slug).to eq('new-slug')
    expect(Page.where(id: base_id + 2)).to be_empty
  end

  it 'rolls back when validation fails' do
    base_id = build_page_id
    delete_id = base_id + 1
    Page.create!(id: delete_id, slug: 'delete-me', title: 'Delete me', lang: 'en')

    result = described_class.call(
      page: { id: base_id, title: 'Missing slug', lang: 'en' },
      delete_id: delete_id
    )

    expect(result[:upserted]).to eq(0)
    expect(result[:deleted]).to eq(0)
    expect(result[:errors]).not_to be_empty
    expect(Page.where(id: delete_id)).not_to be_empty
    expect(Page.where(id: base_id)).to be_empty
  end

  it 'collects errors when page id is missing' do
    result = described_class.call(page: { slug: 'missing-id', title: 'Missing id', lang: 'en' }, delete_id: nil)

    expect(result[:upserted]).to eq(0)
    expect(result[:errors]).to eq([{ id: nil, error: 'id is required' }])
  end

  it 'collects errors when page id is not an integer' do
    result = described_class.call(page: { id: 'abc', slug: 'bad-id', title: 'Bad id', lang: 'en' }, delete_id: nil)

    expect(result[:upserted]).to eq(0)
    expect(result[:errors]).to eq([{ id: 'abc', error: 'id must be an integer' }])
  end

  it 'maps parent field to parent_id' do
    parent_id = build_page_id
    child_id = parent_id + 1

    described_class.call(page: { id: parent_id, slug: 'parent', title: 'Parent', lang: 'en' }, delete_id: nil)
    described_class.call(page: { id: child_id, parent: parent_id, slug: 'child', title: 'Child', lang: 'en' }, delete_id: nil)

    expect(Page.find(child_id).parent_id).to eq(parent_id)
  end
end
