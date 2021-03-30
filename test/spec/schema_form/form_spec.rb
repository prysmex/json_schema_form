require 'json_schema_form_test_helper'

class FormTest < Minitest::Test

  #########
  #builder#
  #########

  def test_example_is_valid
    form_example = JsonSchemaForm::SchemaFormExamples.form
    assert_empty SchemaForm::Form.new(form_example).errors
  end

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
      text_input: JsonSchemaForm::SchemaFormExamples.text_input
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

    #test all properties
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

  def test_response_set_in_builder
    form_example = JsonSchemaForm::SchemaFormExamples.form
    form_example[:definitions] = {
      :"response_set_1" => JsonSchemaForm::SchemaFormExamples.response_set
    }
    assert_instance_of SchemaForm::ResponseSet, SchemaForm::Form.new(form_example)[:definitions][:response_set_1]
  end

  def test_allOf_in_builder
    form_example = JsonSchemaForm::SchemaFormExamples.form
    form_example[:allOf] = [{}]
    assert_instance_of JsonSchema::Schema, SchemaForm::Form.new(form_example)[:allOf].first
  end

  def test_allOf_in_builder
    form_example = JsonSchemaForm::SchemaFormExamples.form
    form_example[:allOf] = [{}]
    assert_instance_of JsonSchema::Schema, SchemaForm::Form.new(form_example)[:allOf].first
  end

end