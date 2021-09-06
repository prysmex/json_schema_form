require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class TextInputTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JSF::FormExamples.text_input
    instance = JSF::Forms::Field::TextInput.new(hash)
    assert_empty instance.errors
  end

end