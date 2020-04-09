# frozen_string_literal: true

module PaginationConcern
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 10

  def objects_count
    object_model.count
  end

  def set_objects_count_header
    response.headers['X-Total-Count'] = objects_count
    response.headers['Access-Control-Expose-Headers'] = 'X-Total-Count'
  end

  def page_params
    page = params.fetch(:page, 0).to_i
    per_page_param = params.fetch(:per_page, DEFAULT_PER_PAGE)
    per_page = per_page_param.blank? ? DEFAULT_PER_PAGE : per_page_param
    [page, per_page]
  end

  def pagination_offset
    page = page_params.first
    per_page = page_params.last.to_i
    offset_count = page.to_i * per_page - per_page
    offset_count.negative? ? 0 : offset_count
  end

  def per_page
    page_params.last
  end
end
