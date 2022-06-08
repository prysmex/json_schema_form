require 'test_helper'
require_relative 'concerns/base'

class SignatureTest < Minitest::Test

  ##################
  ###VALIDATIONS####
  ##################

  # @todo

  ##############
  ###METHODS####
  ##############

  def test_sample_value
    field = JSF::Forms::Field::Signature.new(JSF::Forms::FormBuilder.example('signature'))
    sample = field.sample_value
    assert_equal true, JSONSchemer.schema(field.legalize!.as_json).valid?(sample)
  end

end