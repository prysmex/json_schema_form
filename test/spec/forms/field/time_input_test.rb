# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/base'

class TimeInputTest < Minitest::Test
  include BaseFieldTests

  ###############
  # VALIDATIONS #
  ###############


  # @todo

  ###########
  # METHODS #
  ###########

  def test_sample_value
    field = JSF::Forms::Field::TimeInput.new(JSF::Forms::FormBuilder.example('time_input'))
    sample = field.sample_value

    assert_equal true, JSONSchemer.schema(field.legalize!.as_json).valid?(sample)
  end

  # def test_format
  #   valid = %w[00:00 04:00 10:20 14:30 18:30 23:59]
  #   invalid = %w[24:59 27:00 13:60 01:72]
  # end

end