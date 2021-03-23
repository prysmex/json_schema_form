require "test_helper"

class SchemaTest < Minitest::Test
  
  #schemable
  def test_can_be_empty
    assert_empty JsonSchema::Schema.new()
  end

  def test_supports_all_single_json_schema_types
    TestHelper::JSON_SCHEMA_TYPES.each do |type|
      assert_equal type, JsonSchema::Schema.new({type: type})[:type]
    end
  end

  def test_supports_multiple_schema_types
    sample = TestHelper::JSON_SCHEMA_TYPES.sample(2)
    instance = JsonSchema::Schema.new({type: sample })
    assert_equal sample.size, (instance[:type] & sample).size
  end

  def test_can_have_non_schema_keys
    instance = JsonSchema::Schema.new({this_is_not_json_schema_compliant: true})
    assert_equal true, instance[:this_is_not_json_schema_compliant]
  end
  
  def test_responds_to_meta
    assert_respond_to JsonSchema::Schema.new({type: 'string'}), :meta
  end

  def test_meta_can_be_set_on_instantiation
    instance = JsonSchema::Schema.new({type: 'string'}, {some_meta: true})
    assert_equal true, instance.meta[:some_meta]
  end

  def test_responds_to_types
    assert_respond_to JsonSchema::Schema.new({type: 'string'}), :types
  end

  def test_types_always_returns_array_when_present
    assert_equal 'string', JsonSchema::Schema.new({type: 'string'}).types.first
    assert_equal 'string', JsonSchema::Schema.new({type: ['string']}).types.first
  end

  def test_types_may_return_nil
    assert_nil JsonSchema::Schema.new({}).types
  end

  def test_root_parent_is_nil_when_root
    assert_nil JsonSchema::Schema.new({}).root_parent
  end

  def test_root_parent
    parent = JsonSchema::Schema.new()
    assert_same parent, JsonSchema::Schema.new({}, {parent: parent}).root_parent
  end

  def test_key_name_returns_property_key
    instance = JsonSchema::Schema.new({properties: {prop1: {type: 'string'}}})
    assert_equal :prop1, instance[:properties][:prop1].key_name
  end

  def test_required?
    instance = JsonSchema::Schema.new({required: [:prop1], properties: {prop1: {type: 'string'}}})
    assert_equal true, instance[:properties][:prop1].required?
  end

  def test_raises_error_with_invalid_type
    assert_raises(Dry::Types::ConstraintError) { JsonSchema::Schema.new({type: 'invalid_type'}) }
  end

  def test_raises_error_with_invalid_type_array
    assert_raises(Dry::Types::ConstraintError) { JsonSchema::Schema.new({type: []}) }
    assert_raises(Dry::Types::ConstraintError) { JsonSchema::Schema.new({type: ['invalid_type']}) }
  end

  def test_empty_dependent_conditions_no_parent
    instance = JsonSchema::Schema.new()
    assert_empty instance.dependent_conditions
    assert_equal false, instance.has_dependent_conditions?
    assert_empty instance.dependent_conditions_for_value('some_value') {false}
    assert_empty instance.dependent_conditions_for_value('some_value') {true}
  end

  def test_empty_dependent_conditions_with_parent
    instance = JsonSchema::Schema.new({
      properties: {
        with_dependent_conditions: {type: 'string'},
        no_dependent_conditions: {type: 'string'}
      },
      allOf: [
        {
          if: {properties: {with_dependent_conditions: {const: 'correct_value'}}},
          then: {properties: {}}
        }
      ]
    })

    #child_with_conditions
    child_with_conditions = instance[:properties][:with_dependent_conditions]
    refute_empty child_with_conditions.dependent_conditions
    assert_equal true, child_with_conditions.has_dependent_conditions?
    assert_empty = child_with_conditions.dependent_conditions_for_value('other_value'){ true }
    assert_empty child_with_conditions.dependent_conditions_for_value('correct_value'){ false }
    refute_empty child_with_conditions.dependent_conditions_for_value('correct_value'){ true }

    #child_no_conditions
    child_no_conditions = instance[:properties][:no_dependent_conditions]
    assert_empty child_no_conditions.dependent_conditions
    assert_equal false, child_no_conditions.has_dependent_conditions?
    assert_empty child_no_conditions.dependent_conditions_for_value('correct_value'){ true }
  end
  
  ###########
  #buildable#
  ###########

  #hash
  def test_additionalProperties_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({additionalProperties: {}})[:additionalProperties]
  end
  def test_contains_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({contains: {}})[:contains]
  end
  def test_definitions_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({definitions: {def1: {}}})[:definitions][:def1]
  end
  def test_dependencies_transform_hash
    instance = JsonSchema::Schema.new({dependencies: {def1: {}, def2: []}})
    assert_instance_of JsonSchema::Schema, instance[:dependencies][:def1]
    assert_instance_of ::Array, instance[:dependencies][:def2]
  end
  def test_if_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({if: {}})[:if]
  end
  def test_then_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({then: {}})[:then]
  end
  def test_else_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({else: {}})[:else]
  end
  def test_not_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({not: {}})[:not]
  end
  def test_properties_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({properties: {prop1: {}}})[:properties][:prop1]
  end
  def test_items_transform_hash
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({items: {}})[:items]
  end

  #array
  def test_allOf_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({allOf: [{}]})[:allOf].first
  end
  def test_anyOf_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({anyOf: [{}]})[:anyOf].first
  end
  def test_oneOf_transform
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({oneOf: [{}]})[:oneOf].first
  end
  def test_items_transform_array
    assert_instance_of JsonSchema::Schema, JsonSchema::Schema.new({items: [{}]})[:items].first
  end

  ###########
  #arrayable#
  ###########

  # no tests needed

  #############
  #booleanable#
  #############

  # no tests needed

  ##########
  #nullable#
  ##########

  # no tests needed

  ############
  #numberable#
  ############

  # no tests needed

  ############
  #objectable#
  ############

  # add_property
  def test_add_property
    instance = JsonSchema::Schema.new()
    instance.add_property('prop1', {type: 'string'})
    refute_nil JsonSchema::Schema, instance.dig(:properties, :type)
  end

  # remove_property
  def test_remove_property
    instance = JsonSchema::Schema.new({properties: {prop1: {}}})
    instance.remove_property('prop1')
    assert_equal 0, instance[:properties].size
  end

  # add_required_property
  def test_add_required_property
    instance = JsonSchema::Schema.new()
    instance.add_required_property(:prop1)
    assert_equal 'prop1', instance[:required].first
  end

  # remove_required_property
  def test_remove_required_property
    instance = JsonSchema::Schema.new()
    assert_nil instance[:required]
    instance.add_required_property(:prop1)
    instance.remove_required_property(:prop1)
    assert_nil instance[:required].first
  end

  ############
  #stringable#
  ############

  # no tests needed

end