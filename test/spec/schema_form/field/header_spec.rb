require 'json_schema_form_test_helper'
require_relative 'field_methods_spec'

class HeaderTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JsonSchemaForm::SchemaFormExamples.header
    instance = SchemaForm::Field::Header.new(hash)
    assert_empty instance.errors
  end

end