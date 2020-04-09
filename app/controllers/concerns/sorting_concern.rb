# frozen_string_literal: true

module SortingConcern
  extend ActiveSupport::Concern

  def sort_params
    Hash[*params.fetch(:sort, '').split(',').map(&:to_sym)]
  end
end

