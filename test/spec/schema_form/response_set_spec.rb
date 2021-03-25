require 'test_helper'

class ResponseSetTest < Minitest::Test
  
  include TestHelper::Examples

  def test_anyOf_transform
    example = build_example_with_example_response(:default)
    instance = SchemaForm::ResponseSet.new(example)
    assert_instance_of SchemaForm::Response, instance[:anyOf].first
  end

  def test_default_example_is_valid
    example = build_example_with_example_response(:default)
    instance = SchemaForm::ResponseSet.new(example)
    assert_empty instance.errors({is_inspection: false})
  end

  def test_inspection_example_is_valid
    example = build_example_with_example_response(:is_inspection)
    instance = SchemaForm::ResponseSet.new(example)
    assert_empty instance.errors({is_inspection: true})
  end

  def test_get_response_from_value
    example = build_example_with_example_response(:default)
    instance = SchemaForm::ResponseSet.new(example)
    assert_equal 'no_score_1', instance.get_response_from_value('no_score_1')&.[](:const)
    assert_nil instance.get_response_from_value('something_random')
  end

  def test_valid_for_locale
    example = build_example_with_example_response(:default)
    instance = SchemaForm::ResponseSet.new(example)
    assert_equal true, instance.valid_for_locale?(:en)

    instance[:anyOf][0][:displayProperties][:i18n][:en] = ''
    assert_equal false, instance.valid_for_locale?(:en)

    instance[:anyOf][0][:displayProperties][:i18n][:en] = nil
    assert_equal false, instance.valid_for_locale?(:en)
  end

end