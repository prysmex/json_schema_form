require 'json_schema_form_test_helper'
require_relative 'field_methods_spec'

class CheckboxTest < Minitest::Test
  
  include BaseMethodsTests
  include ResponseSettableTests
  
  def test_default_example_is_valid
    hash = JsonSchemaForm::SchemaFormExamples.checkbox
    instance = SchemaForm::Field::Checkbox.new(hash)
    assert_empty instance.errors
  end

  def test_response_set_id
    hash = JsonSchemaForm::SchemaFormExamples.checkbox
    instance = SchemaForm::Field::Checkbox.new(hash)
    assert_equal "#/definitions/__test_response_set_id__", instance.response_set_id
  end

  # def test_max_score
  # end

  # def test_score_for_value
  # end

  # def test_value_fails
  # end
  
end