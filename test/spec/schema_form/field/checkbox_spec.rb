require 'test_helper'
require_relative 'field_methods_spec'

class CheckboxTest < Minitest::Test
  
  include TestHelper::Examples
  include BaseMethodsTests
  include ResponseSettableTests
  
  def test_default_example_is_valid
    hash = get_parsed_example('/schema_form/field/checkbox.json')
    instance = SchemaForm::Field::Checkbox.new(hash)
    assert_empty instance.errors
  end

  def test_response_set_id
    hash = get_parsed_example('/schema_form/field/checkbox.json')
    instance = SchemaForm::Field::Checkbox.new(hash)
    assert_equal "#/definitions/__test_response_set_id__", instance.response_set_id
  end

  # def test_max_score
  # end

  # def test_score_for_value
  # end

  # def test_value_fails
  # end
  
end