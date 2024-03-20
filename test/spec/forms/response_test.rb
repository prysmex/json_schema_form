# frozen_string_literal: true

require 'test_helper'

class ResponseTest < Minitest::Test

  ###############
  # VALIDATIONS #
  ###############

  def test_no_unknown_keys_allowed
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Response) && key == :schema }

    errors = JSF::Forms::Response.new({array_key: [], other_key: 1}).errors(if: error_proc)
    # unknown keys
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]
    # required keys
    refute_nil errors[:type]
  end

  def test_valid_for_locale
    instance = JSF::Forms::Response.new({
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

  ###########
  # METHODS #
  ###########

  def test_score_values
    # valid_values
    [nil, 0, 0.3, 7].each do |v|
      instance = JSF::Forms::Response.new({ score: v })

      assert_nil instance.errors(optional_if: ->(_, k) { k == :scoring })[:score]
    end

    # invalid_values
    [-1, -1.1].each do |v|
      instance = JSF::Forms::Response.new({ score: v })

      refute_nil instance.errors(optional_if: ->(_, k) { k == :scoring })[:score]
    end
  end

  def test_scored?
    assert_equal false, JSF::Forms::Response.new({ score: nil }).scored?
    assert_equal true, JSF::Forms::Response.new({ score: 1 }).scored?
  end

end