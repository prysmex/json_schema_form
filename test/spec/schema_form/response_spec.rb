require 'json_schema_form_test_helper'

class ResponseTest < Minitest::Test

  def test_valid_for_locale
    instance = SchemaForm::Response.new({
      displayProperties: {
        i18n: {
          es: 'some label',
          en: '',
          de: nil
        }
      }
    })
    assert_equal true, instance.valid_for_locale?(:es)
    assert_equal false, instance.valid_for_locale?(:en)
    assert_equal false, instance.valid_for_locale?(:de)
    assert_equal false, instance.valid_for_locale?(:ru)
  end
  
  def test_default_example_is_valid
    hash = JsonSchemaForm::SchemaFormExamples.response[:default]
    instance = SchemaForm::Response.new(hash)
    assert_empty instance.errors
  end

  def test_inspection_example_is_valid
    hash = JsonSchemaForm::SchemaFormExamples.response[:is_inspection]
    instance = SchemaForm::Response.new(hash)
    assert_empty instance.errors({is_inspection: true})
  end

  # def test_type_must_be_present
  # end

  # def test_type_must_equal_string
  # end

  # def test_const_must_be_present
  # end

  # def test_const_must_be_a_string
  # end

end