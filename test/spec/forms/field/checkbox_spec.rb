require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'
require_relative 'methods/response_settable_spec'

class CheckboxTest < Minitest::Test
  
  include BaseMethodsTests
  include ResponseSettableTests
  
  def test_default_example_is_valid
    hash = JSF::FormExamples.checkbox
    instance = JSF::Forms::Field::Checkbox.new(hash)
    assert_empty instance.errors
  end

  # def test_max_score
  # end

  # def test_score_for_value
  # end

  # def test_value_fails
  # end
  
end