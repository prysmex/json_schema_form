require 'test_helper'
require_relative 'concerns/base'

class SwitchTest < Minitest::Test

  include BaseFieldTests

  ##################
  ###VALIDATIONS####
  ##################

  # @todo

  # @override
  def test_valid_for_locale
    hash = JSF::Forms::FormBuilder.example('switch')
    
    [:label, :trueLabel, :falseLabel].each do |label_key|
      instance = JSF::Forms::Field::Switch.new(hash)

      instance.set_label_for_locale('')
      assert_equal false, instance.valid_for_locale?

      instance.set_label_for_locale(nil)
      assert_equal false, instance.valid_for_locale?

      instance.dig(:displayProperties, :i18n, label_key).delete(JSF::Forms::DEFAULT_LOCALE)
      assert_equal false, instance.valid_for_locale?
    end
  end

  ##############
  ###METHODS####
  ##############

  def test_i18n_value
    field = JSF::Forms::Field::Switch.new(JSF::Forms::FormBuilder.example('switch'))
    locale = JSF::Forms::DEFAULT_LOCALE
    SuperHash::Utils.bury(field, :displayProperties, :i18n, :trueLabel, locale, 'positive')
    SuperHash::Utils.bury(field, :displayProperties, :i18n, :falseLabel, locale, 'negative')
    assert_equal 'positive', field.i18n_value(true, locale)
    assert_equal 'negative', field.i18n_value(false, locale)
  end

  # max_score

  def test_max_score
    assert_equal 1, JSF::Forms::Field::Switch.new.max_score
  end

  # score_for_value

  def test_score_for_value
    instance = JSF::Forms::Field::Switch.new

    assert_equal 1, instance.score_for_value(true)
    assert_equal 0, instance.score_for_value(false)
    assert_nil instance.score_for_value(nil)
    assert_raises(TypeError){instance.score_for_value(1)}
  end

  def test_scored?
    instance = JSF::Forms::Field::Switch.new
    assert_equal true, instance.scored?
  end

  def test_sample_value
    field = JSF::Forms::Field::Switch.new(JSF::Forms::FormBuilder.example('switch'))
    sample = field.sample_value
    assert_equal true, JSONSchemer.schema(field.legalize!.as_json).valid?(sample)
  end

end