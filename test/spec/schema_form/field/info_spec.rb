require 'json_schema_form_test_helper'
require_relative 'field_methods_spec'

class InfoTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JsonSchemaForm::SchemaFormExamples.info
    instance = SchemaForm::Field::Info.new(hash)
    assert_empty instance.errors
  end

end