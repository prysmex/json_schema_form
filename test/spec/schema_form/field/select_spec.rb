require "test_helper"
require_relative 'field_methods_spec'

class SelectTest < Minitest::Test

  include TestHelper::Examples
  include BaseMethodsTests
  include ResponseSettableTests
  
  def test_default_example_is_valid
    hash = get_parsed_example('/schema_form/field/select.json')
    instance = SchemaForm::Field::Select.new(hash)
    assert_empty instance.errors
  end

end