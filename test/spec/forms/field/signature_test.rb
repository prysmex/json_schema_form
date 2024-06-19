# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/base'

class SignatureTest < Minitest::Test

  ###############
  # VALIDATIONS #
  ###############

  # @todo

  def test_match_parent_required
    form = JSF::Forms::FormBuilder.build do
      append_property(:signature_1, example('signature'))
      append_property(:signature_2, example('signature'), required: true)
      append_property(:signature_3, example('signature')) do |f|
        f[:required] = %w[signature name]
      end
      append_property(:signature_4, example('signature'), required: true) do |f|
        f[:required] = %w[signature name]
      end
    end

    assert_empty form.dig('properties', 'signature_1').errors
    assert_equal({'required' => ['must match parent required']}, form.dig('properties', 'signature_2').errors)
    assert_equal({'required' => ['must match parent required']}, form.dig('properties', 'signature_3').errors)
    assert_empty form.dig('properties', 'signature_4').errors
  end

  def test_signature_must_be_required
    form = JSF::Forms::FormBuilder.build do
      append_property(:signature_1, example('signature'), required: true) do |f|
        f[:required] = %w[name]
      end
      append_property(:signature_2, example('signature'), required: true) do |f|
        f[:required] = %w[signature]
      end
      append_property(:signature_3, example('signature'), required: true) do |f|
        f[:required] = %w[name signature]
      end
    end

    assert_equal({'required' => ['if required, signature and name must be required']}, form.dig('properties', 'signature_1').errors)
    assert_equal({'required' => ['if required, signature and name must be required']}, form.dig('properties', 'signature_2').errors)
    assert_empty form.dig('properties', 'signature_3').errors
  end

  ###########
  # METHODS #
  ###########

  def test_sample_value
    field = JSF::Forms::Field::Signature.new(JSF::Forms::FormBuilder.example('signature'))
    sample = field.sample_value

    assert_equal true, JSONSchemer.schema(field.legalize!.as_json).valid?(sample)
  end

end