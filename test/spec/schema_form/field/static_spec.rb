require "test_helper"
require_relative 'field_methods_spec'

class StaticTest < Minitest::Test

  include TestHelper::Examples
  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = get_parsed_example('/schema_form/field/static.json')
    instance = SchemaForm::Field::Static.new(hash)
    assert_empty instance.errors
  end

  def test_valid_for_locale
  end

end