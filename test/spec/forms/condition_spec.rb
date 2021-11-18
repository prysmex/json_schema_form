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
      prop = append_property(:switch_1, example('switch'))

      append_conditional_property(:switch_2, example('switch'), dependent_on: :switch_1, type: :const, value: true)
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
      prop = append_property(:switch_1, example('switch'))

      append_conditional_property(:switch_2, example('switch'), dependent_on: :switch_1, type: :not_const, value: true)
    end

    condition = form.dig(:allOf, 0)

    assert_equal false, condition.evaluate({'switch_1' => nil})
    assert_equal false, condition.evaluate({'switch_1' => true})
    assert_equal true, condition.evaluate({'switch_1' => false})
  end

end