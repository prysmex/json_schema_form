# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/base'

class SharedTest < Minitest::Test

  include BaseFieldTests

  ###############
  # VALIDATIONS #
  ###############

  def test_no_unknown_keys_allowed
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Field::Shared) && key == :schema }

    errors = JSF::Forms::Field::Shared.new({array_key: [], other_key: 1}).errors(if: error_proc)
    # unknown keys
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]
    # required keys
    refute_nil errors[:displayProperties]
  end

  def test_ref_regex
    assert_nil JSF::Forms::Field::Shared.new({'$ref': '#/$defs/hello'}).errors[:$ref]
    refute_nil JSF::Forms::Field::Shared.new({'$ref': '/$defs/hello'}).errors[:$ref]
    refute_nil JSF::Forms::Field::Shared.new({'$ref': '#/properties/hello'}).errors[:$ref]
  end

  ###########
  # METHODS #
  ###########

  # shared_def_pointer

  # db_id

  # db_id=

  # shared_def
end