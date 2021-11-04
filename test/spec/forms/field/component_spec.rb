require 'json_schema_form_test_helper'
require_relative 'methods/base_spec'

class ComponentTest < Minitest::Test

  include BaseMethodsTests

  ##################
  ###VALIDATIONS####
  ##################

  def test_no_unknown_keys_allowed
    errors = JSF::Forms::Field::Component.new({array_key: [], other_key: 1}).errors
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]
  end

  def test_ref_regex
    assert_nil JSF::Forms::Field::Component.new({'$ref': '#/definitions/hello'}).errors[:'$ref']
    refute_nil JSF::Forms::Field::Component.new({'$ref': '/definitions/hello'}).errors[:'$ref']
    refute_nil JSF::Forms::Field::Component.new({'$ref': '#/properties/hello'}).errors[:'$ref']
  end

  ##############
  ###METHODS####
  ##############

  # component_definition_pointer

  # component_definition_pointer=

  # component_ref_id

  # component_definition
end