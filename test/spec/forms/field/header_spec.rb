require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class HeaderTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JSF::FormExamples.header
    instance = JSF::Forms::Field::Header.new(hash)
    assert_empty instance.errors
  end

end