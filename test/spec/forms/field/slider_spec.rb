require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class SliderTest < Minitest::Test

  include BaseMethodsTests

  #########
  #helpers#
  #########

  # v => 3
  # moves => 3
  # @return => 0.003
  def move_decimail_point(v, moves)
    (v.to_f / (10 ** moves)).round(moves)
  end

  #######
  #tests#
  #######

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

  def test_enum_length
    enum = (0...JSF::Forms::Field::Slider::MAX_ENUM_SIZE).to_a

    instance = JSF::Forms::Field::Slider.new({
      enum: enum
    })

    assert_nil instance.errors[:_enum_size_]

    instance[:enum].push(JSF::Forms::Field::Slider::MAX_ENUM_SIZE)

    assert_instance_of String, instance.errors[:_enum_size_]
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
      assert_nil instance.errors[:_enum_interval_]
  
      # force errors
      instance[:enum].map!{|v| v + rand(100)}
      assert_instance_of String, instance.errors[:_enum_interval_]
    end

  end

  def test_max_precision
    instance = JSF::Forms::Field::Slider.new({
      enum: [move_decimail_point(1, JSF::Forms::Field::Slider::MAX_PRECISION)]
    })

    # no error
    assert_nil instance.errors[:_enum_precision_]

    instance[:enum] = [move_decimail_point(1, JSF::Forms::Field::Slider::MAX_PRECISION + 1)]
    assert_instance_of String, instance.errors[:_enum_precision_]
  end

  # def test_max_score
  # end

end