require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class DateInputTest < Minitest::Test
  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JSF::FormExamples.date_input
    instance = JSF::Forms::Field::DateInput.new(hash)
    assert_empty instance.errors
  end
end