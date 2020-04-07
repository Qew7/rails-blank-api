class ApplicationController < ActionController::API
  include ErrorHandlingConcern

  def object_fields
    object_model.attribute_names.map(&:to_sym) - ApplicationRecord::SERVICE_FIELDS
  end

  def object_model
    self.controller_name.classify.constantize
  end
end
