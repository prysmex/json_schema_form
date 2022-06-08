require 'test_helper'
require_relative 'concerns/base'

class DateInputTest < Minitest::Test
  include BaseFieldTests

  ##################
  ###VALIDATIONS####
  ##################

  # @todo

  ##############
  ###METHODS####
  ##############

  def test_sample_value
    field = JSF::Forms::Field::DateInput.new(JSF::Forms::FormBuilder.example('date_input'))
    sample = field.sample_value
    assert_equal true, JSONSchemer.schema(field.legalize!.as_json).valid?(sample)
  end

end