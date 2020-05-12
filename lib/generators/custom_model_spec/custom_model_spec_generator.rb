class CustomModelSpecGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  def create_spec_file
    template 'specs/spec.erb', "spec/models/#{modules_as_folders}_spec.rb"
  end

  private

  def model
    class_name.constantize
  end

  def modules_as_folders
    model.name.underscore.sub('::', '/')
  end

  def fabric_name
    table_name.singularize
  end

  def valid_instance_spec
    """
  describe 'validity' do
    it 'is valid when valid' do
      expect(build(#{valid_fabric_params})).to be_valid
    end
  end
    """ unless relations.find { |relation| relation.last.polymorphic? }.present?
  end

  def valid_fabric_params
    [":#{fabric_name}", required_traits].compact.join(', ')
  end

  def required_traits
    relations.values
      .reject{ |r| r.options[:polymorphic] }
      .select { |r| !r.options[:optional] && r.belongs_to? }
      .map { |r| ":with_#{r.name.to_s}" }
      .presence
  end

  def relations
    model.reflections
  end

  def validations_specs
    model.validators.flatten.map do |validator|
      next if validator_for_belongs_to_relation?(validator)
      """
    it { should #{validation_method(validator)} }
      """
    end.compact.join('').delete_suffix("\n     ")
  end

  def validations_count
    model.validators.flatten.reject {|validator| validator_for_belongs_to_relation?(validator) }.count
  end

  def validation_method(validator)
    case validator.class.name
    when 'ActiveRecord::Validations::PresenceValidator'
      "validate_presence_of(:#{validator.attributes.first})"
    when 'ActiveRecord::Validations::LengthValidator'
      "validate_length_of(:#{validator.attributes.first})"
    when 'ActiveRecord::Validations::AbsenceValidator'
      "validate_absence_of(:#{validator.attributes.first})"
    when 'ActiveRecord::Validations::UniquenessValidator'
      "validate_uniqueness_of(:#{validator.attributes.first})"
    else
      "unknown validation class, please update 'lib/generators/custom_model_spec/custom_model_spec_generator.rb#validation_method'"
    end
  end

  def validator_for_belongs_to_relation?(validator)
    relations[validator.attributes.first.to_s]&.belongs_to? && validator.options[:message] == :required
  end

  def associations_specs
    relations.map do |relation|
      """
    it { should #{relation_method(relation)} }
      """
    end.join('').delete_suffix("\n     ")
  end

  def relation_method(relation)
    relation_name, relation_object = relation
    case relation_object.class.name
    when 'ActiveRecord::Reflection::BelongsToReflection'
      belongs_to_relation_method(relation)
    when 'ActiveRecord::Reflection::HasOneReflection'
      has_one_relation_method(relation)
    when 'ActiveRecord::Reflection::HasManyReflection', 'ActiveRecord::Reflection::ThroughReflection'
      has_many_relation_method(relation)
    when 'ActiveRecord::Reflection::HasAndBelongsToManyReflection'
      has_and_belongs_to_many_relation_method(relation)
    else
      "unknown validation class, please update 'lib/generators/custom_model_spec/custom_model_spec_generator.rb#relation_method'"
    end
  end

  def belongs_to_relation_method(relation)
    relation_name, relation_object = relation
    options_with_prefix = %i[primary_key foreign_key]
    options = relation_object.options
    options_string = options.map do |option, value|
      next if option == :polymorphic
      option = "with_#{option}" if option.in?(options_with_prefix)
      ".#{option}(#{value.inspect})"
    end.join
    "belong_to(:#{relation_name})#{options_string}"
  end

  def has_one_relation_method(relation)
    relation_name, relation_object = relation
    options_with_prefix = %i[primary_key foreign_key]
    options = relation_object.options
    options_string = options.map do |option, value|
      next if option == :as
      option = "with_#{option}" if option.in?(options_with_prefix)
      ".#{option}(#{value.inspect})"
    end.join
    "have_one(:#{relation_name})#{options_string}"
  end

  def has_many_relation_method(relation)
    relation_name, relation_object = relation
    options_with_prefix = %i[primary_key foreign_key]
    options = relation_object.options
    options_string = options.map do |option, value|
      next if option == :as
      option = "with_#{option}" if option.in?(options_with_prefix)
      ".#{option}(#{value.inspect})"
    end.join
    "have_many(:#{relation_name})#{options_string}"
  end

  def has_and_belongs_to_many_relation_method(relation)
    relation_name, relation_object = relation
    options_with_prefix = %i[primary_key foreign_key]
    options = relation_object.options
    options_string = options.map do |option, value|
      next if option == :as
      option = "with_#{option}" if option.in?(options_with_prefix)
      ".#{option}(#{value.inspect})"
    end.join
    "have_and_belong_to_many(:#{relation_name})#{options_string}"
  end

  def enums_specs
    """
  describe 'enums' do
    #{model.defined_enums.map { |enum, _| "it { should define_enum_for(:#{enum.to_s}) }" }.join("\n")}
  end
    """
  end
end
