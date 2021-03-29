require 'json_schema_form_test_helper'
require_relative 'field_methods_spec'

class SliderTest < Minitest::Test

  include BaseMethodsTests
  
  def test_default_example_is_valid
    hash = JsonSchemaForm::SchemaFormExamples.slider
    instance = SchemaForm::Field::Slider.new(hash)
    assert_empty instance.errors
  end

  def test_valid_for_locale
    instance = SchemaForm::Field::Slider.new({
      displayProperties: {
        i18n: {
          label: {
            es1: 'opciones',
            es2: 'opciones',
            es3: 'opciones',
            es4: '',
            es5: nil,
            es6: 'opciones'
          },
          enum: {
            es1: {'1': 'uno'},
            es2: {'1': ''},
            es3: {'1': nil},
            es4: {'1': 'opciones'},
            es5: {'1': 'opciones'},
            es6: {},
          },
        },
      },
      enum: [1]
    })
    assert_equal true, instance.valid_for_locale?(:es1)
    assert_equal false, instance.valid_for_locale?(:es2)
    assert_equal false, instance.valid_for_locale?(:es3)
    assert_equal false, instance.valid_for_locale?(:es4)
    assert_equal false, instance.valid_for_locale?(:es5)
    assert_equal false, instance.valid_for_locale?(:es6)
    assert_equal false, instance.valid_for_locale?(:es7)
  end

end