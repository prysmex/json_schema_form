require "test_helper"
require_relative 'field_methods_spec'

class TextInputTest < Minitest::Test

  include TestHelper::Examples
  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = get_parsed_example('/schema_form/field/text_input.json')
    instance = SchemaForm::Field::TextInput.new(hash)
    assert_empty instance.errors
  end

end