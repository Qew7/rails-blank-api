class ApplicationRecord < ActiveRecord::Base
  SERVICE_FIELDS = [:id, :created_at, :updated_at].freeze

  self.abstract_class = true
end
