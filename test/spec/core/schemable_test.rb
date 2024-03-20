# frozen_string_literal: true

require 'test_helper'

class StrictTypesTest < Minitest::Test
  include TestHelper::SampleClassHooks

  def test_can_be_empty
    assert_empty SampleSchema.new
  end

  def test_can_have_non_schema_keys
    instance = SampleSchema.new({this_is_not_json_schema_compliant: true})

    assert_equal true, instance[:this_is_not_json_schema_compliant]
  end

  # type attribute

  def test_supports_all_single_json_schema_types
    TestHelper::JSON_SCHEMA_TYPES.each do |type|
      assert_equal type, SampleSchema.new({type:})[:type]
    end
  end

  def test_supports_multiple_schema_types
    sample = TestHelper::JSON_SCHEMA_TYPES.sample(2)
    instance = SampleSchema.new({type: sample })

    assert_equal sample.size, (instance[:type] & sample).size
  end

  def test_raises_error_with_invalid_type
    assert_raises(Dry::Types::ConstraintError) { SampleSchema.new({type: 'invalid_type'}) }
  end

  def test_raises_error_with_invalid_type_array
    assert_raises(Dry::Types::ConstraintError) { SampleSchema.new({type: []}) }
    assert_raises(Dry::Types::ConstraintError) { SampleSchema.new({type: ['invalid_type']}) }
  end

  # meta

  def test_responds_to_meta
    assert_respond_to SampleSchema.new({type: 'string'}), :meta
  end

  def test_meta
    schema = SampleSchema.new

    assert_equal false, schema.meta[:is_subschema]
    assert_empty schema.meta[:path]
    assert_nil schema.meta[:parent]
  end

  def test_meta_can_be_set_on_instantiation
    instance = SampleSchema.new({type: 'string'}, {meta: {some_meta: true}})

    assert_equal true, instance.meta[:some_meta]
  end

  # types

  def test_types_always_returns_array_when_present
    assert_equal 'string', SampleSchema.new({type: 'string'}).types.first
    assert_equal 'string', SampleSchema.new({type: ['string']}).types.first
  end

  # find_parent

  def test_find_parent_returns_nil_when_root
    assert_nil SampleSchema.new.find_parent
  end

  def test_find_parent
    SampleSchema.include JSF::Core::Buildable

    schema = SampleSchema.new({
      properties: {
        prop1: {type: 'number'}
      },
      allOf: [
        {
          if: {},
          then: {
            properties: {prop2: {type: 'string'}}
          }
        }
      ]
    })

    assert_nil schema[:properties][:prop1].find_parent { |_, _| false }
    assert_same schema, schema[:properties][:prop1].find_parent { |_, _| true }
    assert_same schema, schema[:properties][:prop1].find_parent { |current, _| current == schema }
  end

  # root_parent

  def test_root_parent_is_nil_when_root
    assert_nil SampleSchema.new({}).root_parent
  end

  def test_root_parent
    SampleSchema.include JSF::Core::Buildable
    schema = SampleSchema.new({
      allOf: [
        {
          if: {},
          then: {
            properties: {prop2: {type: 'string'}}
          }
        }
      ]
    })

    assert_same schema, schema[:allOf][0][:then][:properties][:prop2].root_parent
  end

  # required?

  def test_required?
    SampleSchema.include JSF::Core::Buildable

    instance = SampleSchema.new({required: ['prop1'], properties: {prop1: {type: 'string'}}})

    assert_equal true, instance[:properties][:prop1].required?
  end

  # key_name

  def test_key_name_returns_property_key
    SampleSchema.include JSF::Core::Buildable

    instance = SampleSchema.new({properties: {prop1: {type: 'string'}}})

    assert_equal 'prop1', instance[:properties][:prop1].key_name
  end

  # dependent_conditions

  def test_empty_dependent_conditions_no_parent
    instance = SampleSchema.new

    assert_nil instance.dependent_conditions
    assert_equal false, instance.has_dependent_conditions?
    assert_nil instance.dependent_conditions_for_value('some_value') { false }
    assert_nil instance.dependent_conditions_for_value('some_value') { true }
  end

  def test_empty_dependent_conditions_with_parent
    SampleSchema.include JSF::Core::Buildable

    instance = SampleSchema.new({
      properties: {
        with_dependent_conditions: {type: 'string'},
        no_dependent_conditions: {type: 'string'}
      },
      allOf: [
        {
          if: {properties: {with_dependent_conditions: {const: 'correct_value'}}},
          then: {properties: {}}
        },
        {
          if: {properties: {other: {const: 'correct_value'}}},
          then: {properties: {}}
        }
      ]
    })

    # child_with_conditions
    child_with_conditions = instance[:properties][:with_dependent_conditions]

    assert_equal 1, child_with_conditions.dependent_conditions.size
    assert_same instance[:allOf][0], child_with_conditions.dependent_conditions.first
    assert_equal true, child_with_conditions.has_dependent_conditions?
    assert_empty child_with_conditions.dependent_conditions_for_value('correct_value') { false }
    assert_equal 1, child_with_conditions.dependent_conditions_for_value('correct_value') { true }.size

    # child_no_conditions
    child_no_conditions = instance[:properties][:no_dependent_conditions]

    assert_empty child_no_conditions.dependent_conditions
    assert_equal false, child_no_conditions.has_dependent_conditions?
    assert_empty child_no_conditions.dependent_conditions_for_value('correct_value') { true }
  end

  # set_strict_type

  def test_set_strict_type
    TestHelper::JSON_SCHEMA_TYPES.each do |type|
      SampleSchema.set_strict_type(type)
      assert_raises(::Dry::Types::ConstraintError) { SampleSchema.new({type: 'whatever'}) } # fails
      assert_equal type, SampleSchema.new({type:})[:type]                              # valid
    end
  end

end