require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class StaticTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JSF::FormExamples.static
    instance = JSF::Forms::Field::Static.new(hash)
    assert_empty instance.errors
  end

  # @override
  def test_valid_for_locale
  end

end