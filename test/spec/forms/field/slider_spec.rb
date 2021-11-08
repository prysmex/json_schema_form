require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class SliderTest < Minitest::Test

  include BaseMethodsTests

  # v => 3
  # moves => 3
  # @return => 0.003
  def move_decimail_point(v, moves)
    (v.to_f / (10 ** moves)).round(moves)
  end

  ##################
  ###VALIDATIONS####
  ##################

  # @todo

  # @override
  def test_valid_for_locale
    options = ['text', '', nil]

    # test combinations
    options.each do |option|
      options.each do |opt|
        instance = JSF::Forms::Field::Slider.new({
          displayProperties: {
            i18n: {
              label: {
                locale1: option
              },
              enum: {
                locale1: {'1': opt}
              },
            },
          },
          enum: [1]
        })
        expected = !option.to_s.empty? && !opt.to_s.empty?
        assert_equal expected, instance.valid_for_locale?(:locale1)
      end
    end

    # test missing locale
    instance = JSF::Forms::Field::Slider.new({
      displayProperties: {
        i18n: {
          label: {
            locale1: 'text'
          },
          enum: {
            locale1: {'1': 'text'}
          },
        },
      },
      enum: [1, 2]
    })
    assert_equal false, instance.valid_for_locale?(:locale1)

  end
  
  ##############
  ###METHODS####
  ##############

  # max_score

  def test_max_score
    instance = JSF::Forms::Field::Slider.new({
      enum: [1,2,4]
    })

    assert_equal 4, instance.max_score
  end

  # score for value

  def test_score_for_value
    instance = JSF::Forms::Field::Slider.new({
      enum: [1,2,4]
    })

    assert_equal 2, instance.score_for_value(2)
  end

  def test_enum_values_must_be_positive
    instance = JSF::Forms::Field::Slider.new({
      enum: [-1, 2, 3]
    })
    refute_nil instance.errors[:enum]
  end
  
  def test_enum_length
    enum = (0...JSF::Forms::Field::Slider::MAX_ENUM_SIZE).to_a
    instance = JSF::Forms::Field::Slider.new({
      enum: [0]
    })

    refute_nil instance.errors[:enum]               # min
    instance[:enum] = enum
    assert_nil instance.errors[:enum]
    instance[:enum].push(instance[:enum].last + 1)
    refute_nil instance.errors[:enum]               # max
  end

  def test_enum_spacing
    integer_enum = (0...JSF::Forms::Field::Slider::MAX_ENUM_SIZE).to_a
    float_enum = (0...JSF::Forms::Field::Slider::MAX_ENUM_SIZE).map do |v|
      move_decimail_point(v, JSF::Forms::Field::Slider::MAX_PRECISION)
    end

    enums = [
      integer_enum,
      float_enum
    ]

    enums.each do |enum|
      instance = JSF::Forms::Field::Slider.new({
        enum: enum
      })
  
      # no errors
      assert_empty instance.errors(if: ->(obj, key) { key == :enum_interval })
  
      # force errors
      instance[:enum].map!{|v| v + rand(100)}
      refute_empty instance.errors(if: ->(obj, key) { key == :enum_interval })
    end

  end

  def test_max_precision
    instance = JSF::Forms::Field::Slider.new({
      enum: [move_decimail_point(1, JSF::Forms::Field::Slider::MAX_PRECISION)]
    })

    # no error
    assert_empty instance.errors(if: ->(obj, key) { key == :enum_precision })

    instance[:enum] = [move_decimail_point(1, JSF::Forms::Field::Slider::MAX_PRECISION + 1)]
    refute_empty instance.errors(if: ->(obj, key) { key == :enum_precision })
  end

end