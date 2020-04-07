# frozen_string_literal: true

module ErrorHandlingConcern
  extend ActiveSupport::Concern
  included do
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActionController::ParameterMissing, with: :unprocessable_entity
  end

  private

  def not_found
    head :not_found
  end

  def unprocessable_entity
    head :unprocessable_entity
  end

  def user_not_authorized
    head :unauthorized
  end

  def forbidden
    head :forbidden
  end
end
