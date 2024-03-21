# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/base'
require_relative 'concerns/response_settable'

class CheckboxTest < Minitest::Test

  include BaseFieldTests
  include ResponseSettableTests

  ###############
  # VALIDATIONS #
  ###############

  # @todo

  ###########
  # METHODS #
  ###########

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
          response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
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
          response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
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
    assert_equal 5, form[:properties][:checkbox1].score_for_value(%w[option0 option2])
    assert_nil form[:properties][:checkbox1].score_for_value(['random'])
  end

  # value_fails

  def test_value_fails
    form = JSF::Forms::FormBuilder.build do
      # response set
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'option0'
          r[:failed] = true
        end
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'option1'
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
    assert_equal true, form[:properties][:checkbox1].value_fails?(%w[option0 option1])
    assert_equal false, form[:properties][:checkbox1].value_fails?(['random'])
  end

  # sample_value

  def test_sample_value
    form = JSF::Forms::FormBuilder.build do
      add_response_set(:response_set_1, example('response_set'))
      add_response_set(:response_set_2, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'option0'
          r[:failed] = true
        end
      end

      # no response set
      append_property(:checkbox_1, example('checkbox'))
      # empty response set
      append_property(:checkbox_2, example('checkbox')).tap do |field|
        field.response_set_id = :response_set_1
      end
      # response set
      append_property(:checkbox_3, example('checkbox')).tap do |field|
        field.response_set_id = :response_set_2
      end
    end

    sample = {
      'checkbox_1' => form[:properties][:checkbox_1].sample_value,
      'checkbox_2' => form[:properties][:checkbox_2].sample_value,
      'checkbox_3' => form[:properties][:checkbox_3].sample_value
    }.compact

    form.send_recursive(:legalize!)

    assert_equal true, JSONSchemer.schema(form.as_json).valid?(sample)
  end

end