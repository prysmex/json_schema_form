require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'
require_relative 'methods/response_settable_spec'

class CheckboxTest < Minitest::Test
  
  include BaseMethodsTests
  include ResponseSettableTests

  # max_score

  def test_max_score_no_response_set
    instance = JSF::Forms::Field::Checkbox.new(JSF::Forms::FormBuilder.example('checkbox'))

    assert_nil instance.max_score
  end

  def test_max_score
    form = JSF::Forms::FormBuilder.build do
      # response set
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        [nil, 2, 5, 3].each_with_index do |score, i|
          response_set.add_response(example('response', :is_inspection)).tap do |r|
            r[:const] = "option#{i}"
            r[:score] = score
          end
        end
      end

      # fields
      append_property(:checkbox1, example('checkbox')).tap do |field|
        field.response_set_id = :response_set_1
      end
      append_property(:checkbox2, example('checkbox'))
    end

    assert_equal 10, form[:properties][:checkbox1].max_score
    assert_nil form[:properties][:checkbox2].max_score
  end

  # score_for_value

  def test_score_for_value
    form = JSF::Forms::FormBuilder.build do
      # response set
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        [nil, 3, 5].each_with_index do |score, i|
          response_set.add_response(example('response', :is_inspection)).tap do |r|
            r[:const] = "option#{i}"
            r[:score] = score
          end
        end
      end

      # fields
      append_property(:checkbox1, example('checkbox')).tap do |field|
        field.response_set_id = :response_set_1
      end
    end

    assert_nil form[:properties][:checkbox1].score_for_value(['option0'])
    assert_equal 5, form[:properties][:checkbox1].score_for_value(['option0', 'option2'])
    assert_nil form[:properties][:checkbox1].score_for_value(['random'])
  end

  # value_fails

  def test_value_fails
    form = JSF::Forms::FormBuilder.build do
      # response set
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :is_inspection)).tap do |r|
          r[:const] = "option0"
          r[:failed] = true
        end
        response_set.add_response(example('response', :is_inspection)).tap do |r|
          r[:const] = "option1"
          r[:failed] = false
        end
      end

      # fields
      append_property(:checkbox1, example('checkbox')).tap do |field|
        field.response_set_id = :response_set_1
      end
    end

    assert_equal true, form[:properties][:checkbox1].value_fails?(['option0'])
    assert_equal false, form[:properties][:checkbox1].value_fails?(['option1'])
    assert_equal true, form[:properties][:checkbox1].value_fails?(['option0', 'option1'])
    assert_equal false, form[:properties][:checkbox1].value_fails?(['random'])
  end
  
end