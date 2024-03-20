# frozen_string_literal: true

require 'test_helper'

class SharedRefTest < Minitest::Test

  ###############
  # VALIDATIONS #
  ###############

  def test_schema_key_validations
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::SharedRef) && key == :schema }

    errors = JSF::Forms::SharedRef.new({array_key: [], other_key: 1}).errors(if: error_proc)
    # unknown keys
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]
    # required keys
    refute_nil errors['$ref']
  end

  ###########
  # METHODS #
  ###########

  # shared

end