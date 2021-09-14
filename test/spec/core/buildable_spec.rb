require 'json_schema_form_test_helper'

class BuildableTest < Minitest::Test
  include JsonSchemaFormTestHelper::SampleClassHooks

  def setup
    super
    @sample_schema_class.include JSF::Core::Buildable
  end

  # hash attributes

  def test_additionalProperties_transform
    schema = SampleSchema.new({additionalProperties: {}})
    subschema = schema[:additionalProperties]

    assert_instance_of SampleSchema, subschema
    assert_equal true, subschema.meta[:is_subschema]
    assert_equal ['additionalProperties'], subschema.meta[:path]
  end

  def test_contains_transform
    schema = SampleSchema.new({contains: {}})
    subschema = schema[:contains]

    assert_instance_of SampleSchema, subschema
    assert_equal true, subschema.meta[:is_subschema]
    assert_equal ['contains'], subschema.meta[:path]
  end

  def test_definitions_transform
    schema = SampleSchema.new({definitions: {def1: {}}})
    subschema = schema[:definitions][:def1]

    assert_instance_of SampleSchema, subschema
    assert_equal true, subschema.meta[:is_subschema]
    assert_equal ['definitions', 'def1'], subschema.meta[:path]
  end

  def test_dependencies_transform_hash
    schema = SampleSchema.new({dependencies: {dep1: {}, dep2: []}})
    subschema = schema[:dependencies][:dep1]

    assert_instance_of SampleSchema, subschema
    assert_equal true, subschema.meta[:is_subschema]
    assert_equal ['dependencies', 'dep1'], subschema.meta[:path]
    assert_instance_of ::Array, schema[:dependencies][:dep2]
  end

  def test_if_then_else_not_transforms
    ['if', 'then', 'else', 'not'].each do |type|
      schema = SampleSchema.new({type => {}})
      subschema = schema[type]
  
      assert_instance_of SampleSchema, subschema
      assert_equal true, subschema.meta[:is_subschema]
      assert_equal [type], subschema.meta[:path]
    end
  end

  def test_items_transform_hash
    schema = SampleSchema.new({items: {}})
    subschema = schema[:items]

    assert_instance_of SampleSchema, subschema
    assert_equal true, subschema.meta[:is_subschema]
    assert_equal ['items'], subschema.meta[:path]
  end

  def test_properties_transform
    schema = SampleSchema.new({properties: {prop1: {}}})
    subschema = schema[:properties][:prop1]

    assert_instance_of SampleSchema, subschema
    assert_equal true, subschema.meta[:is_subschema]
    assert_equal ['properties', 'prop1'], subschema.meta[:path]
  end


  # array attributes

  def test_allOf_transform
    assert_instance_of SampleSchema, SampleSchema.new({allOf: [{}]})[:allOf].first
  end

  def test_anyOf_transform
    assert_instance_of SampleSchema, SampleSchema.new({anyOf: [{}]})[:anyOf].first
  end

  def test_oneOf_transform
    assert_instance_of SampleSchema, SampleSchema.new({oneOf: [{}]})[:oneOf].first
  end

  def test_items_transform_array
    assert_instance_of SampleSchema, SampleSchema.new({items: [{}]})[:items].first
  end

  # custom attributes_transform_proc

  def test_attributes_transform_proc

    test_proc = Proc.new do |attribute, value, instance, init_options|
      if attribute == 'if'
        value.to_h
      else
        SampleSchema.new(value, init_options)
      end
    end

    schema = SampleSchema.new(
      {if: {type: 'string'}, then: {enum: ['option_1']}},
      attributes_transform_proc: test_proc
    )

    assert_instance_of ActiveSupport::HashWithIndifferentAccess, schema[:if] # ToDo: should this return Hash?
    assert_instance_of SampleSchema, schema[:then]
  end

  # complex examples

  def test_complex_example
    schema = SampleSchema.new(
      {
        properties: {
          prop1: { type: 'string' }
        },
        allOf: [
          {
            if: {properties: { prop1: { const: "test" } }},
            then: {
              properties: {
                prop2: { type: 'number' }
              },
              allOf: [
                {
                  if: {properties: { prop2: { const: 1 } }},
                  then: {
                    properties: {
                      prop3: { type: 'number' }
                    }
                  }
                }
              ]
            }
          }
        ]
      }
    )

    subschema = schema['allOf'][0]['then']['allOf'][0]['then']['properties']['prop3']
    path = subschema.meta[:path]

    assert_instance_of SampleSchema, subschema
    assert_equal ['allOf', 0, 'then', 'allOf', 0, 'then', 'properties', 'prop3'], path
  end

end