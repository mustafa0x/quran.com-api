# frozen_string_literal: true

module Api::V4
  class PagesController < ApiController
    def index
      lang = fetch_locale

      @pages = Page
                 .visible
                 .for_lang(lang)
                 .order(:parent_id, :ord, :id)

      parent_id = params[:parent_id].presence || params[:parent].presence
      @pages = @pages.where(parent_id: parent_id) if parent_id.present?

      render
    end

    def show
      @page = find_page(params[:id])

      if @page
        render
      else
        render_404('Page not found')
      end
    end

    private

    def find_page(key)
      requested_lang = fetch_locale

      base = Page.visible.where(id: key.to_i).or(Page.visible.where(slug: key))

      base.find_by(lang: requested_lang) || base.find_by(lang: 'en')
    end
  end
end