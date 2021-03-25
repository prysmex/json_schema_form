require 'test_helper'

module ValidatableTestMethods

  include TestHelper::SampleClassHooks
  
  TYPE_ERROR_MESSAGE = 'type is not whitelisted'.freeze

  def setup
    super
    SampleSchema.include(JsonSchema::SchemaMethods::Schemable)
    SampleSchema.include(JsonSchema::SchemaMethods::Buildable)
    SampleSchema.include(JsonSchema::Validations::Validatable)
  end

  def override_own_errors_as_empty(klass = SampleSchema)
    klass.define_method(:own_errors) do |passthru|
      {}
    end
  end

  def override_own_errors_with_whitelisted_types(klass = SampleSchema)
    klass.define_method(:own_errors) do |passthru|
      errors = {}
      if !TestHelper::JSON_SCHEMA_TYPES.include?(self[:type])
        errors[:type] = TYPE_ERROR_MESSAGE
      end
      errors
    end
  end

end


class ValidatableTest < Minitest::Test
  include ValidatableTestMethods

  def test_raises_error_if_own_errors_not_overriden
    assert_raises(::NoMethodError) { SampleSchema.new.errors }
  end

  def test_empty_schema_no_errors
    override_own_errors_as_empty
    assert_empty SampleSchema.new.errors
  end

  def test_empty_schema_with_errors
    override_own_errors_with_whitelisted_types
    refute_empty SampleSchema.new.errors
  end

  def test_random_hash_should_not_raise_error_when_building_errors
    override_own_errors_as_empty
    instance = SampleSchema.new({some_hash: {test: 1}})
    assert_empty instance.errors
  end

  def test_random_array_should_not_raise_error_when_building_errors
    override_own_errors_as_empty
    instance = SampleSchema.new({some_array: [{hash_1: true}]})
    assert_empty instance.errors
  end

  def test_additional_properties_as_boolean
    override_own_errors_as_empty
    instance = SampleSchema.new({additionalProperties: true})
    assert_empty instance.errors
  end

  def test_all_subschema_keys_no_errors
    override_own_errors_as_empty
    instance = SampleSchema.new({
      properties: {prop1: {items: {}}},
      if: {},
      then: {},
      else: {},
      additionalProperties: {},
      dependencies: {prop1: {}, prop2: ['prop1']},
      contains: {},
      not: {},
      definitions: {prop1: {}},
      items: [{}],
      allOf: [{}],
      anyOf: [{}],
      oneOf: [{}]
    })
    
    assert_empty instance.errors
  end

  def test_additionalProperties_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', properties: {prop1: {}}})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:properties, :prop1, :type)
  end

  def test_contains_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', contains: {}})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:contains, :type)
  end

  def test_definitions_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', definitions: {prop1: {}}})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:definitions, :prop1, :type)
  end

  def test_dependencies_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', dependencies: {prop1: {}}})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:dependencies, :prop1, :type)
  end

  def test_else_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', else: {}})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:else, :type)
  end

  def test_if_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', if: {}})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:if, :type)
  end

  def test_items_hash_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', items: {}})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:items, :type)
  end

  def test_items_array_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', items: [{}]})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:items, 0, :type)
  end

  def test_not_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', not: {}})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:not, :type)
  end

  def test_properties_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', properties: {prop1: {}}})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:properties, :prop1, :type)
  end

  def test_then_key_with_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({type: 'object', then: {}})
    assert_equal TYPE_ERROR_MESSAGE, instance.errors.dig(:then, :type)
  end

  def test_nested_errors
    override_own_errors_with_whitelisted_types
    instance = SampleSchema.new({
      type: 'object',
      properties: {
        prop1:{
          type: 'string',
          allOf: [
            {
              type: 'string',
              items: [
                {type: 'number'},
                {}
              ]
            }
          ]
        }
      }
    })
    errors = instance.errors
    assert_equal 1, SuperHash::Helpers.flatten_to_root(errors).keys.size
    assert_equal TYPE_ERROR_MESSAGE, errors.dig(:properties, :prop1, :allOf, 0, :items, 1, :type)
  end

end