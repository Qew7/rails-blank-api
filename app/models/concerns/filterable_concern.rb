# frozen_string_literal: true

module FilterableConcern
  extend ActiveSupport::Concern

  class_methods do
    def filter_data(filtering_params)
      results = self.where(nil)
      nonlikable_columns = self.columns.select { |c| c.sql_type.in?(['bigint','integer','boolean']) }.map(&:name)
      filtering_params.each do |key, value|
        next if value.blank?
        results = results.where(key => value['from']..value['to']) if value.kind_of?(Hash) && value.keys.sort == ['from', 'to']
        if key.in?(nonlikable_columns)
          results = results.where(key => value) if value.kind_of?(String)
        else
          results = results.where(results.arel_table[key.to_sym].matches("%#{value}%")) if value.kind_of?(String)
        end
      end
      results
    end
  end
end
