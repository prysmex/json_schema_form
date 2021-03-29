require 'json_schema_form_test_helper'
require_relative 'field_methods_spec'

class SelectTest < Minitest::Test

  include BaseMethodsTests
  include ResponseSettableTests
  
  def test_default_example_is_valid
    hash = JsonSchemaForm::SchemaFormExamples.select
    instance = SchemaForm::Field::Select.new(hash)
    assert_empty instance.errors
  end

end