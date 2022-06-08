require 'test_helper'
require_relative 'concerns/base'

class StaticTest < Minitest::Test

  include BaseFieldTests

  ##################
  ###VALIDATIONS####
  ##################

  # @todo

  # @override
  def test_valid_for_locale
  end
  
  ##############
  ###METHODS####
  ##############

  def test_sample_value
    field = JSF::Forms::Field::Static.new(JSF::Forms::FormBuilder.example('static'))
    sample = field.sample_value
    assert_equal true, JSONSchemer.schema(field.legalize!.as_json).valid?(sample)
  end

end