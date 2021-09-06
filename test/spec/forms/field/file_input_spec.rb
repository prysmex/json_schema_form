require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class FileInputTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JSF::FormExamples.file_input
    instance = JSF::Forms::Field::FileInput.new(hash)
    assert_empty instance.errors
  end

end