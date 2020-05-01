class CustomFactoryGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  def create_factory_file
    template 'factories/factory.erb', "spec/factories/models/#{table_name.singularize}.rb"
  end

  def initialize_traits_storage
    @traits = {}
  end

  private

  def attribute_value_from_type(type)
    case type
    when 'string', 'character varying'
      '{ Faker::Lorem.word }'
    when 'text', 'character varying(1000)'
      '{ Faker::Lorem.sentences.join(' ') }'
    when 'datetime','timestamp without time zone'
      '{ Faker::Time.between(from: DateTime.now - 3, to: DateTime.now) }'
    when 'date'
      '{ Faker::Date.between(from: 2.days.ago, to: Date.today) }'
    when 'integer'
      '{ Faker::Number.number(digits: 4) }'
    when 'double precision'
      '{ Faker::Number.decimal(l_digits: 2) }'
    when 'jsonb','json'
      "{ Faker::Json.shallow_json(width: 3, options: { key: 'Seinfeld.character', value: 'Seinfeld.quote' }) }"
    when 'boolean'
      '{ [true,false].sample }'
    else
      "{ \'unknown type \'#{type}\', please update \'lib/generators/custom_factory/custom_factory_generator#attribute_value_from_type\' }"
    end
  end

  def attributes
    @traits = {}
    @reserved_words = %w(send object_id extend instance_eval raise caller method transient sequence factory trait)
    model = class_name.constantize
    columns_to_ignore = model::SERVICE_FIELDS
    model.columns.map do |c|
      next if c.name.to_sym.in?(columns_to_ignore)
      if reference_column?(c)
        format_reference_column(c)
      else
        format_column(c)
      end
    end.compact.join("\n")
  end

  def traits
    @traits.sort.map do |name, value|
      """
    trait :#{name} do
      #{value}
    end
      """
    end.join("").delete_suffix("\n      ")
  end

  def reference_column?(column)
    column.name.ends_with?('_id') && column.sql_type == 'bigint'
  end

  def format_reference_column(column)
    reference_name = column.name.delete_suffix('_id')
    @traits['with_' + reference_name] = "#{reference_name} { build(:#{reference_name}) }"
    reference_name = reference_name.in?(@reserved_words) ? "add_attribute(:#{reference_name})" : reference_name
    "    #{reference_name} { nil }"
  end

  def format_column(column)
    column_name = column.name
    @traits['without_' + column_name] = "#{column_name} { nil }" if !column.null && column.default.nil?
    column_name = column_name.in?(@reserved_words) ? "add_attribute(:#{column_name})" : column_name
    "    #{column_name} #{attribute_value_from_type(column.sql_type)}"
  end
end
