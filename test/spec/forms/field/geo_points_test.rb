# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/base'

class GeoPointsTest < Minitest::Test

  include BaseFieldTests

  ###############
  # VALIDATIONS #
  ###############

  # @todo

  ###########
  # METHODS #
  ###########

  def test_sample_value
    field = JSF::Forms::Field::GeoPoints.new(JSF::Forms::FormBuilder.example('geo_points'))
    sample = field.sample_value

    assert_equal true, JSONSchemer.schema(field.legalize!.as_json).valid?(sample)
  end

end