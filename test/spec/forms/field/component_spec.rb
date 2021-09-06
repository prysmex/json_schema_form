require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class ComponentTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JSF::FormExamples.component
    instance = JSF::Forms::Field::Component.new(hash)
    assert_empty instance.errors
  end

end