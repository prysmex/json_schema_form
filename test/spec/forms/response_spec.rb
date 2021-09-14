require 'json_schema_form_test_helper'

class ResponseTest < Minitest::Test

  ##################
  ###VALIDATIONS####
  ##################

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

  ##############
  ###METHODS####
  ##############

  def test_score_values
    # valid_values
    [nil, 0, 0.3, 7].each do |v|
      instance = JSF::Forms::Response.new({ score: v })
      assert_nil instance.errors({is_inspection: true})[:score]
    end

    # invalid_values
    [-1, -1.1].each do |v|
      instance = JSF::Forms::Response.new({ score: v })
      refute_nil instance.errors({is_inspection: true})[:score]
    end
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