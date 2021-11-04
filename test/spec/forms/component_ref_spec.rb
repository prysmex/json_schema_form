require 'json_schema_form_test_helper'

class ComponentRefTest < Minitest::Test

  ##################
  ###VALIDATIONS####
  ##################

  def test_no_unknown_keys_allowed
    errors = JSF::Forms::ComponentRef.new({array_key: [], other_key: 1}).errors
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]
  end

  ##############
  ###METHODS####
  ##############

  # component

end