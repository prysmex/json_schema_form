require 'test_helper'

class ConditionTest < Minitest::Test

  ##################
  ###VALIDATIONS####
  ##################

  ##############
  ###METHODS####
  ##############

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
      prop = append_property(:switch_1, example('switch')) do |f, key|
        append_conditional_property(:switch_2, example('switch'), dependent_on: key, type: :const, value: true)
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
    assert_equal true, instance.negated

    instance[:if][:properties][:some_prop] = {const: true}
    assert_equal false, instance.negated
  end

  def test_evaluate
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch')) do |f, key|
        append_conditional_property(:switch_1_1, example('switch'), dependent_on: key, type: :const, value: true)
        append_conditional_property(:switch_1_2, example('switch'), dependent_on: key, type: :not_const, value: true)
        append_conditional_property(:switch_1_3, example('switch'), dependent_on: key, type: :enum, value: [true])
        append_conditional_property(:switch_1_4, example('switch'), dependent_on: key, type: :not_enum, value: [true])
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