require "test_helper"

JSON_SCHEMA_TYPES = ['array','boolean','null','number','object','string']

class SchemaTest < Minitest::Test
  
  #schemable

  def test_can_be_empty
    assert_empty JsonSchemaForm::Schema.new()
  end

  def test_supports_all_single_json_schema_types
    JSON_SCHEMA_TYPES.each do |type|
      assert_equal type, JsonSchemaForm::Schema.new({type: type})[:type]
    end
  end

  def test_supports_multiple_schema_types
    sample = JSON_SCHEMA_TYPES.sample(2)
    instance = JsonSchemaForm::Schema.new({type: sample })
    assert_equal sample.size, (instance[:type] & sample).size
  end

  def test_can_have_non_schema_keys
    instance = JsonSchemaForm::Schema.new({this_is_not_json_schema_compliant: true})
    assert_equal true, instance[:this_is_not_json_schema_compliant]
  end
  
  def test_responds_to_meta
    assert_respond_to JsonSchemaForm::Schema.new({type: 'string'}), :meta
  end

  def test_meta_can_be_set_on_instantiation
    instance = JsonSchemaForm::Schema.new({type: 'string'}, {some_meta: true})
    assert_equal true, instance.meta[:some_meta]
  end

  def test_responds_to_types
    assert_respond_to JsonSchemaForm::Schema.new({type: 'string'}), :types
  end

  def test_types_always_returns_array_when_present
    assert_equal 'string', JsonSchemaForm::Schema.new({type: 'string'}).types.first
    assert_equal 'string', JsonSchemaForm::Schema.new({type: ['string']}).types.first
  end

  def test_types_may_return_nil
    assert_nil JsonSchemaForm::Schema.new({}).types
  end

  def test_root_parent_is_nil_when_root
    assert_nil JsonSchemaForm::Schema.new({}).root_parent
  end

  def test_root_parent
    parent = JsonSchemaForm::Schema.new()
    assert_same parent, JsonSchemaForm::Schema.new({}, {parent: parent}).root_parent
  end

  def test_key_name_returns_property_key
    instance = JsonSchemaForm::Schema.new({properties: {prop1: {type: 'string'}}})
    assert_equal :prop1, instance[:properties][:prop1].key_name
  end

  def test_required?
    instance = JsonSchemaForm::Schema.new({required: [:prop1], properties: {prop1: {type: 'string'}}})
    assert_equal true, instance[:properties][:prop1].required?
  end

  def test_raises_error_with_invalid_type
    assert_raises(Dry::Types::ConstraintError) { JsonSchemaForm::Schema.new({type: 'invalid_type'}) }
  end

  def test_raises_error_with_invalid_type_array
    assert_raises(Dry::Types::ConstraintError) { JsonSchemaForm::Schema.new({type: []}) }
    assert_raises(Dry::Types::ConstraintError) { JsonSchemaForm::Schema.new({type: ['invalid_type']}) }
  end

  ###########
  #buildable#
  ###########

  #ToDo dependent_conditions

  ###########
  #arrayable#
  ###########

  #############
  #booleanable#
  #############

  ##########
  #nullable#
  ##########

  ############
  #numberable#
  ############

  ############
  #objectable#
  ############

  ############
  #stringable#
  ############

end