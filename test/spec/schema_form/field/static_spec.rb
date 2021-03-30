require 'json_schema_form_test_helper'
require_relative 'field_methods_spec'

class StaticTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JsonSchemaForm::SchemaFormExamples.static
    instance = SchemaForm::Field::Static.new(hash)
    assert_empty instance.errors
  end

  def test_valid_for_locale
  end

end