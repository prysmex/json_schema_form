require 'json_schema_form_test_helper'
require_relative 'field_methods_spec'

class DateInputTest < Minitest::Test
  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JsonSchemaForm::SchemaFormExamples.date_input
    instance = SchemaForm::Field::DateInput.new(hash)
    assert_empty instance.errors
  end
end