require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class SwitchTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    example = JSF::FormExamples.switch
    instance = JSF::Forms::Field::Switch.new(example)
    assert_empty instance.errors
  end

  def test_default_example_is_valid_for_locale
    example = JSF::FormExamples.switch
    instance = JSF::Forms::Field::Switch.new(example)
    assert_equal true, instance.valid_for_locale?
  end

  # @override
  def test_valid_for_locale
    hash = JSF::FormExamples.switch
    
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

  def test_max_score
    assert_equal 1, JSF::Forms::Field::Switch.new.max_score
  end

  def test_max_score_for_value
    instance = JSF::Forms::Field::Switch.new
    assert_equal 1, instance.score_for_value(true)
    assert_equal 0, instance.score_for_value(false)
  end

end