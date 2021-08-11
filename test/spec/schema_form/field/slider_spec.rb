require 'json_schema_form_test_helper'
require_relative 'field_methods_spec'

class SliderTest < Minitest::Test

  include BaseMethodsTests

  # v => 3
  # moves => 3
  # @return => 0.003
  def move_decimail_point(v, moves)
    (v.to_f / (10 ** moves)).round(moves)
  end
  
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

  def test_enum_length
    enum = (0...SchemaForm::Field::Slider::MAX_ENUM_SIZE).to_a

    instance = SchemaForm::Field::Slider.new({
      enum: enum
    })

    assert_nil instance.errors[:_enum_size_]

    instance[:enum].push(SchemaForm::Field::Slider::MAX_ENUM_SIZE)

    assert_instance_of String, instance.errors[:_enum_size_]
  end

  def test_enum_spacing
    integer_enum = (0...SchemaForm::Field::Slider::MAX_ENUM_SIZE).to_a
    float_enum = (0...SchemaForm::Field::Slider::MAX_ENUM_SIZE).map do |v|
      move_decimail_point(v, SchemaForm::Field::Slider::MAX_PRECISION)
    end

    enums = [
      integer_enum,
      float_enum
    ]

    enums.each do |enum|
      instance = SchemaForm::Field::Slider.new({
        enum: enum
      })
  
      # no errors
      assert_nil instance.errors[:_enum_interval_]
  
      # force errors
      instance[:enum].map!{|v| v + rand(100)}
      assert_instance_of String, instance.errors[:_enum_interval_]
    end

  end

  def test_max_precision
    instance = SchemaForm::Field::Slider.new({
      enum: [move_decimail_point(1, SchemaForm::Field::Slider::MAX_PRECISION)]
    })

    # no error
    assert_nil instance.errors[:_enum_precision_]

    instance[:enum] = [move_decimail_point(1, SchemaForm::Field::Slider::MAX_PRECISION + 1)]
    assert_instance_of String, instance.errors[:_enum_precision_]
  end

end