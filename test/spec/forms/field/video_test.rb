# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/base'

class VideoTest < Minitest::Test

  include BaseFieldTests

  ###############
  # VALIDATIONS #
  ###############

  # @todo

  ###########
  # METHODS #
  ###########

  def test_sample_value
    field = JSF::Forms::Field::Video.new(JSF::Forms::FormBuilder.example('video'))
    sample = field.sample_value

    assert_equal true, JSONSchemer.schema(field.legalize!.as_json).valid?(sample)
  end
end