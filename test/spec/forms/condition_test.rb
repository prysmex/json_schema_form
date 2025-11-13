# frozen_string_literal: true

require 'test_helper'

class ConditionTest < Minitest::Test

  ###############
  # VALIDATIONS #
  ###############

  ###########
  # METHODS #
  ###########

  def test_condition_property_key
    instance = JSF::Forms::Condition.new({
      if: {
        properties: {
          some_prop: {
            not: {
              const: true
            }
          }
        }
      },
      then: {}
    })

    assert_equal 'some_prop', instance.condition_property_key
  end

  def test_condition_property
    prop = nil
    form = JSF::Forms::FormBuilder.build do
      prop = append_property(:switch_1, example('switch')) do
        append_property(:switch_2, example('switch'), type: :const, value: true)
      end
    end

    assert_same prop, form.dig(:allOf, 0).condition_property
  end

  def test_negated
    instance = JSF::Forms::Condition.new({
      if: {
        properties: {
          some_prop: {
            not: {
              const: true
            }
          }
        }
      },
      then: {}
    })

    assert_equal true, instance.negated?

    instance[:if][:properties][:some_prop] = {const: true}

    assert_equal false, instance.negated?
  end

  def test_condition_type
    instance = JSF::Forms::Condition.new({
      if: {
        properties: {
          some_prop: {}
        }
      },
      then: {}
    })

    # not const
    instance['if']['properties']['some_prop'] = { not: { const: true } }

    assert_equal 'not_const', instance.condition_type

    # not enum
    instance['if']['properties']['some_prop'] = { not: { enum: true } }

    assert_equal 'not_enum', instance.condition_type

    # const
    instance['if']['properties']['some_prop'] = { const: true }

    assert_equal 'const', instance.condition_type

    # const
    instance['if']['properties']['some_prop'] = { enum: true }

    assert_equal 'enum', instance.condition_type
  end

  def test_value
    instance = JSF::Forms::Condition.new({
      if: {
        properties: {
          some_prop: {}
        }
      },
      then: {}
    })

    # not const
    instance['if']['properties']['some_prop'] = { not: { const: 1 } }

    assert_equal 1, instance.value

    # not enum
    instance['if']['properties']['some_prop'] = { not: { enum: 2 } }

    assert_equal 2, instance.value

    # const
    instance['if']['properties']['some_prop'] = { const: 3 }

    assert_equal 3, instance.value

    # const
    instance['if']['properties']['some_prop'] = { enum: 4 }

    assert_equal 4, instance.value
  end

  def test_set_value
    instance = JSF::Forms::Condition.new({
      if: {
        properties: {
          some_prop: { not: {const: 'hey'} }
        }
      },
      then: {}
    })

    instance.set_value(1)

    assert_equal true, instance.negated?
    assert_equal 'not_const', instance.condition_type
    assert_equal 1, instance.value

    instance.set_value(2, type: 'enum')

    assert_equal false, instance.negated?
    assert_equal 'enum', instance.condition_type
    assert_equal 2, instance.value

    instance.set_value(3, type: 'not_enum')

    assert_equal true, instance.negated?
    assert_equal 'not_enum', instance.condition_type
    assert_equal 3, instance.value
  end

  def test_evaluate
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch')) do
        append_property(:switch_1_1, example('switch'), type: :const, value: true)
        append_property(:switch_1_2, example('switch'), type: :not_const, value: true)
        append_property(:switch_1_3, example('switch'), type: :enum, value: [true])
        append_property(:switch_1_4, example('switch'), type: :not_enum, value: [true])
      end
    end

    # const
    condition = form.dig(:allOf, 0)

    assert_equal false, condition.evaluate({'switch_1' => nil})
    assert_equal true, condition.evaluate({'switch_1' => true})
    assert_equal false, condition.evaluate({'switch_1' => false})

    # enum
    condition = form.dig(:allOf, 2)

    assert_equal false, condition.evaluate({'switch_1' => nil})
    assert_equal true, condition.evaluate({'switch_1' => true})
    assert_equal false, condition.evaluate({'switch_1' => false})

    # not_const
    condition = form.dig(:allOf, 1)

    assert_equal false, condition.evaluate({'switch_1' => nil})
    assert_equal false, condition.evaluate({'switch_1' => true})
    assert_equal true, condition.evaluate({'switch_1' => false})

    # not_enum
    condition = form.dig(:allOf, 3)

    assert_equal false, condition.evaluate({'switch_1' => nil})
    assert_equal false, condition.evaluate({'switch_1' => true})
    assert_equal true, condition.evaluate({'switch_1' => false})
  end

end