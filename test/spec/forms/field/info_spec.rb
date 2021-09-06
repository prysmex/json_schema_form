require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class InfoTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JSF::FormExamples.info
    instance = JSF::Forms::Field::Info.new(hash)
    assert_empty instance.errors
  end

end