# frozen_string_literal: true

module FilteringConcern
  extend ActiveSupport::Concern

  def filter_params
    object_columns = object_model.columns.map(&:name)
    result = params.permit!.to_h.select{ |k, _| k.in?(object_columns) }
    result
  end
end
