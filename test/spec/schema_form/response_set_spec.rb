require 'json_schema_form_test_helper'

class ResponseSetTest < Minitest::Test
  
  def build_example_response_set_with_example_response(type)
    response_set_example = JsonSchemaForm::SchemaFormExamples.response_set
    response_example = JsonSchemaForm::SchemaFormExamples.response[type]
    response_set_example[:anyOf].push(response_example)
    response_set_example
  end

  def build_response_set_instance(type)
    example = build_example_response_set_with_example_response(type)
    SchemaForm::ResponseSet.new(example)
  end

  def test_anyOf_transform
    instance = build_response_set_instance(:default)
    assert_instance_of SchemaForm::Response, instance[:anyOf].first
  end

  def test_default_example_is_valid
    instance = build_response_set_instance(:default)
    assert_empty instance.errors({is_inspection: false})
  end

  def test_inspection_example_is_valid
    instance = build_response_set_instance(:is_inspection)
    assert_empty instance.errors({is_inspection: true})
  end

  def test_get_response_from_value
    instance = build_response_set_instance(:default)
    assert_equal 'no_score_1', instance.get_response_from_value('no_score_1')&.[](:const)
    assert_nil instance.get_response_from_value('something_random')
  end

  def test_valid_for_locale
    instance = build_response_set_instance(:default)
    assert_equal true, instance.valid_for_locale?(:en)

    instance[:anyOf][0][:displayProperties][:i18n][:en] = ''
    assert_equal false, instance.valid_for_locale?(:en)

    instance[:anyOf][0][:displayProperties][:i18n][:en] = nil
    assert_equal false, instance.valid_for_locale?(:en)
  end

end