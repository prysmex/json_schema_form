require 'test_helper'
require_relative 'concerns/base'
require_relative 'concerns/response_settable'

class SelectTest < Minitest::Test

  include BaseFieldTests
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

  # sample_value

  def test_sample_value
    form = JSF::Forms::FormBuilder.build do
      add_response_set(:response_set_1, example('response_set'))
      add_response_set(:response_set_2, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :is_inspection)).tap do |r|
          r[:const] = "option0"
          r[:failed] = true
        end
      end

      # no response set
      append_property(:select_1, example('select'))
      # empty response set
      append_property(:select_2, example('select')).tap do |field|
        field.response_set_id = :response_set_1
      end
      # with response set
      append_property(:select_3, example('select')).tap do |field|
        field.response_set_id = :response_set_2
      end
    end

    sample = {
      'select_1' => form[:properties][:select_1].sample_value,
      'select_2' => form[:properties][:select_2].sample_value,
      'select_3' => form[:properties][:select_3].sample_value,
    }.compact

    form.send_recursive(:legalize!)
    assert_equal true, JSONSchemer.schema(form.as_json).valid?(sample)
  end

end