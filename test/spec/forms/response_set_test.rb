# frozen_string_literal: true

require 'test_helper'

class ResponseSetTest < Minitest::Test

  ###############
  # VALIDATIONS #
  ###############

  def test_no_unknown_keys_allowed
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::ResponseSet) && key == :schema }

    errors = JSF::Forms::ResponseSet.new({array_key: [], other_key: 1}).errors(if: error_proc)

    # unknown keys
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]

    # required keys
    refute_nil errors[:type]
  end

  def test_valid_for_locale
    instance = build_response_set_instance

    assert_equal true, instance.valid_for_locale?

    instance[:anyOf][0].set_translation('')

    assert_equal false, instance.valid_for_locale?

    instance[:anyOf][0].set_translation(nil)

    assert_equal false, instance.valid_for_locale?
  end

  ###########
  # METHODS #
  ###########

  # test helper
  def build_response_set_instance(type = nil)
    response_set_example = JSF::Forms::FormBuilder.example('response_set')
    response_example = JSF::Forms::FormBuilder.example('response', type)
    response_set = JSF::Forms::ResponseSet.new(response_set_example)
    response_set.add_response(response_example)
    response_set
  end

  def test_anyOf_transform
    instance = build_response_set_instance

    assert_instance_of JSF::Forms::Response, instance[:anyOf].first
  end

  def test_get_response_from_value
    instance = build_response_set_instance

    assert_equal 'no_score_1', instance.get_response_from_value('no_score_1')&.[](:const)
    assert_nil instance.get_response_from_value('something_random')
  end

  def test_response_path
    instance = build_response_set_instance

    assert_equal ['anyOf', 0], instance.get_response_from_value('no_score_1').meta[:path]
  end

  # @todo add_response

  # @todo remove_response_from_value

  # @todo get_response_from_value

  # @todo get_failing_responses

  # @todo get_passing_responses

  # @todo legalize!

  def test_scored?
    instance = build_response_set_instance

    assert_equal false, instance.scored?
    instance[:anyOf][0][:score] = 1

    assert_equal true, instance.scored?

    instance = JSF::Forms::ResponseSet.new

    assert_equal false, instance.scored?
  end

end