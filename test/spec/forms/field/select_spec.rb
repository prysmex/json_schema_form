require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'
require_relative 'methods/response_settable_spec'

class SelectTest < Minitest::Test

  include BaseMethodsTests
  include ResponseSettableTests

  ##################
  ###VALIDATIONS####
  ##################

  # @todo

  ##############
  ###METHODS####
  ##############
  
  # max_score

  def test_max_score_no_response_set
    instance = JSF::Forms::Field::Select.new(JSF::Forms::FormBuilder.example('select'))

    assert_nil instance.max_score
  end

  def test_max_score
    form = JSF::Forms::FormBuilder.build do
      # response set
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        [-1, 2, 5, -3].each_with_index do |score, i|
          response_set.add_response(example('response', :is_inspection)).tap do |r|
            r[:const] = "option#{i}"
            r[:score] = score
          end
        end
      end

      # fields
      append_property(:select1, example('select')).tap do |field|
        field.response_set_id = :response_set_1
      end
      append_property(:select2, example('select'))
    end

    assert_equal 5, form[:properties][:select1].max_score
    assert_nil form[:properties][:select2].max_score
  end

  # score_for_value

  def test_score_for_value
    form = JSF::Forms::FormBuilder.build do
      # response set
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :is_inspection)).tap do |r|
          r[:const] = "option0"
          r[:score] = nil
        end
        response_set.add_response(example('response', :is_inspection)).tap do |r|
          r[:const] = "option1"
          r[:score] = -3
        end
      end

      # fields
      append_property(:select1, example('select')).tap do |field|
        field.response_set_id = :response_set_1
      end
    end

    assert_nil form[:properties][:select1].score_for_value('option0')
    assert_equal(-3 , form[:properties][:select1].score_for_value('option1'))
    assert_nil form[:properties][:select1].score_for_value('random')
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
      append_property(:select1, example('select')).tap do |field|
        field.response_set_id = :response_set_1
      end
    end

    assert_equal true, form[:properties][:select1].value_fails?('option0')
    assert_equal false, form[:properties][:select1].value_fails?('option1')
    assert_equal false, form[:properties][:select1].value_fails?('random')
  end

end