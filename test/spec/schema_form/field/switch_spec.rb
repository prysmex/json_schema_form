require 'json_schema_form_test_helper'
require_relative 'field_methods_spec'

class SwitchTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    example = JsonSchemaForm::SchemaFormExamples.switch
    instance = SchemaForm::Field::Switch.new(example)
    assert_empty instance.errors
  end

  def test_default_example_is_valid_for_locale
    example = JsonSchemaForm::SchemaFormExamples.switch
    instance = SchemaForm::Field::Switch.new(example)
    assert_equal true, instance.valid_for_locale?(:en)
  end

  def test_valid_for_locale
    hash = JsonSchemaForm::SchemaFormExamples.switch
    locale = :en
    
    [:label, :trueLabel, :falseLabel].each do |label_key|
      instance = SchemaForm::Field::Switch.new(hash)
      labels = instance.dig(:displayProperties, :i18n, label_key)

      labels[locale] = ''
      assert_equal false, instance.valid_for_locale?(locale)

      labels[locale] = nil
      assert_equal false, instance.valid_for_locale?(locale)

      labels.delete(locale)
      assert_equal false, instance.valid_for_locale?(locale)
    end
  end

  def test_max_score
    assert_equal 1, SchemaForm::Field::Switch.new.max_score
  end

  def test_max_score_for_value
    instance = SchemaForm::Field::Switch.new
    assert_equal 1, instance.score_for_value(true)
    assert_equal 0, instance.score_for_value(false)
  end

end