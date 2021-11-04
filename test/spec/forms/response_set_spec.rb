require 'json_schema_form_test_helper'

class ResponseSetTest < Minitest::Test

  ##################
  ###VALIDATIONS####
  ##################

  def test_no_unknown_keys_allowed
    errors = JSF::Forms::ResponseSet.new({array_key: [], other_key: 1}).errors
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]
  end

  def test_valid_for_locale
    instance = build_response_set_instance(:default)
    assert_equal true, instance.valid_for_locale?

    instance[:anyOf][0].set_translation('')
    assert_equal false, instance.valid_for_locale?

    instance[:anyOf][0].set_translation(nil)
    assert_equal false, instance.valid_for_locale?
  end

  ##############
  ###METHODS####
  ##############

  # helper

  def build_response_set_instance(type)
    response_set_example = JSF::Forms::FormBuilder.example('response_set')
    response_example = JSF::Forms::FormBuilder.example('response', type)
    response_set = JSF::Forms::ResponseSet.new(response_set_example)
    response_set.add_response(response_example)
    response_set
  end

  # tests

  def test_anyOf_transform
    instance = build_response_set_instance(:default)
    assert_instance_of JSF::Forms::Response, instance[:anyOf].first
  end

  def test_get_response_from_value
    instance = build_response_set_instance(:default)
    assert_equal 'no_score_1', instance.get_response_from_value('no_score_1')&.[](:const)
    assert_nil instance.get_response_from_value('something_random')
  end

  def test_response_path
    instance = build_response_set_instance(:default)
    assert_equal ["anyOf", 0], instance.get_response_from_value('no_score_1').meta[:path]
  end

end