# frozen_string_literal: true

class Page < ApplicationRecord
  belongs_to :parent, class_name: 'Page', optional: true
  has_many :children, class_name: 'Page', foreign_key: 'parent_id', inverse_of: :parent, dependent: :nullify

  validates :slug, presence: true
  validates :title, presence: true
  validates :lang, presence: true

  validates :slug, uniqueness: { scope: :lang }
  validates :ord, numericality: { only_integer: true }

  validate :parent_language_matches
  validate :parent_is_not_self

  scope :visible, -> { where(hidden: false) }
  scope :for_lang, ->(lang) { where(lang: lang) }

  private

  def parent_language_matches
    return if parent.nil?
    return if parent.lang == lang

    errors.add(:parent_id, 'must reference a page in the same language')
  end

  def parent_is_not_self
    return if parent_id.blank? || id.blank?
    return unless parent_id == id

    errors.add(:parent_id, 'cannot reference itself')
  end
end
