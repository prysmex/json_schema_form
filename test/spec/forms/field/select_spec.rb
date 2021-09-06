require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'
require_relative 'methods/response_settable_spec'

class SelectTest < Minitest::Test

  include BaseMethodsTests
  include ResponseSettableTests
  
  def test_default_example_is_valid
    hash = JSF::FormExamples.select
    instance = JSF::Forms::Field::Select.new(hash)
    assert_empty instance.errors
  end

end