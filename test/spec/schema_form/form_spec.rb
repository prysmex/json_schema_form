require 'json_schema_form_test_helper'

class FormTest < Minitest::Test

  #############
  #validations#
  #############

  def test_example_is_valid
    form_example = JsonSchemaForm::SchemaFormExamples.form
    assert_empty SchemaForm::Form.new(form_example).errors
  end

  def test_property_key_must_match_property_id
    form_example = JsonSchemaForm::SchemaFormExamples.form
    form = SchemaForm::FormBuilder.build(form_example) do
      append_property :header_1, JsonSchemaForm::SchemaFormExamples.header.merge({:$id => '#/properties/header_1'})
    end
    assert_empty form.errors
    form[:properties][:header_1][:$id] = '#/_properties/header_1'
    refute_empty form.errors
  end

  #ToDo add more

  #########
  #builder#
  #########

  def test_builder
    form_example = JsonSchemaForm::SchemaFormExamples.form
    form_example[:properties] = {
      checkbox: JsonSchemaForm::SchemaFormExamples.checkbox,
      component: JsonSchemaForm::SchemaFormExamples.component,
      date_input: JsonSchemaForm::SchemaFormExamples.date_input,
      header: JsonSchemaForm::SchemaFormExamples.header,
      info: JsonSchemaForm::SchemaFormExamples.info,
      number_input: JsonSchemaForm::SchemaFormExamples.number_input,
      select: JsonSchemaForm::SchemaFormExamples.select,
      slider: JsonSchemaForm::SchemaFormExamples.slider,
      static: JsonSchemaForm::SchemaFormExamples.static,
      text_input: JsonSchemaForm::SchemaFormExamples.text_input,
      file_input: JsonSchemaForm::SchemaFormExamples.file_input
    }
    form_example[:definitions] = {
      :"definition_1" => JsonSchemaForm::SchemaFormExamples.response_set
    }
    form_example[:allOf] = [
      {
        if: {
          properties: {
            select: {const: 1}
          }
        },
        then: {
          properties: {
            checkbox2: JsonSchemaForm::SchemaFormExamples.checkbox
          }
        }
      }
    ]

    form = SchemaForm::Form.new(form_example)

    #test all field types
    form[:properties].each do |name, field|
      classified_name = name.to_s.split('_').collect(&:capitalize).join
      assert_instance_of Object.const_get("SchemaForm::Field::#{classified_name}"), field
    end

    #test definitions
    assert_instance_of SchemaForm::ResponseSet, form[:definitions][:definition_1]

    #test allOf
    assert_instance_of JsonSchema::Schema, form[:allOf].first
    assert_instance_of JsonSchema::Schema, form[:allOf].first[:if]
    assert_instance_of JsonSchema::Schema, form[:allOf].first[:if][:properties][:select]

    #test then
    assert_instance_of SchemaForm::Form, form[:allOf].first[:then]

    #nested properties
    assert_instance_of SchemaForm::Field::Checkbox, form[:allOf].first[:then][:properties][:checkbox2]
  end

  #########
  #methods#
  #########

  def test_valid_for_locale
    form_example = JsonSchemaForm::SchemaFormExamples.form
    form = SchemaForm::Form.new(form_example)

    #default example is valid
    assert_equal true, form.valid_for_locale?

    #ToDo more examples
    # SchemaForm::FormBuilder.new(form) do
    #   append_property :prop1, JsonSchemaForm::SchemaFormExamples.select
    # end

    # form[:properties][:prop1].set_label_for_locale('')
  end

  def test_get_condition
    form_example = JsonSchemaForm::SchemaFormExamples.form
    form_example[:properties][:prop1] = JsonSchemaForm::SchemaFormExamples.select
    form_example[:allOf] = [
      {
        if: {properties: {prop1: {const: 'const'}}},
        then: {properties:{}}
      },
      {
        if: {properties: {prop1: {not: {const: 'not_const'}}}},
        then: {properties:{}}
      },
      {
        if: {properties: {prop1: {enum: ['enum']}}},
        then: {properties:{}}
      },{
        if: {properties: {prop1: {not: {enum: ['not_enum']}}}},
        then: {properties:{}}
      }
    ]
    form = SchemaForm::Form.new(form_example)
    assert_equal 'const', form.get_condition(:prop1, :const, 'const')&.dig(:if, :properties, :prop1, :const)
    assert_equal 'not_const', form.get_condition(:prop1, :not_const, 'not_const')&.dig(:if, :properties, :prop1, :not, :const)
    assert_equal 'enum', form.get_condition(:prop1, :enum, 'enum')&.dig(:if, :properties, :prop1, :enum)&.first
    assert_equal 'not_enum', form.get_condition(:prop1, :not_enum, 'not_enum')&.dig(:if, :properties, :prop1, :not, :enum)&.first

    assert_nil form.get_condition(:prop1, :const, 'other_value')
  end

  # def test_add_or_get_condition
  #   form_example = JsonSchemaForm::SchemaFormExamples.form
  #   form = SchemaForm::Form.new(form_example)
  #   assert_raises(ArgumentError){ form.add_or_get_condition(:prop1, :const, 'const') }

  #   form[]
  # end

end