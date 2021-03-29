require 'json_schema_form_test_helper'
require_relative 'field_methods_spec'

class ComponentTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JsonSchemaForm::SchemaFormExamples.component
    instance = SchemaForm::Field::Component.new(hash)
    assert_empty instance.errors
  end

end