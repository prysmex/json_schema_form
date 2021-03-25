require "test_helper"
require_relative 'field_methods_spec'

class ComponentTest < Minitest::Test

  include TestHelper::Examples
  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = get_parsed_example('/schema_form/field/component.json')
    instance = SchemaForm::Field::Component.new(hash)
    assert_empty instance.errors
  end

end