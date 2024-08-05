# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/base'

class FileInputTest < Minitest::Test

  include BaseFieldTests

  ###############
  # VALIDATIONS #
  ###############

  # @todo

  ###########
  # METHODS #
  ###########

  def test_sample_value
    field = JSF::Forms::Field::FileInput.new(JSF::Forms::FormBuilder.example('file_input'))
    sample = field.sample_value

    assert_equal true, JSONSchemer.schema(field.legalize!.as_json).valid?(sample)
  end

  def test_format
    # # test generic pattern in FileInput schema
    # %w[
    #   ^http.+\.?(?:ang|)$
    #   ^http.+\.?(?:|asdf)$
    #   ^http.+\.?(?:asdf|asdf|)$
    #   ^http.+\.?(?:asdf||asdf)$
    #   ^http.+\.?(?:asdfasdf||)$
    #   ^http.+\.?(?:||asdfasdf)$
    #   ^http.+\.?(?:|)$
    # ].each do |regex_str|
    #   field = JSF::Forms::Field::FileInput.new(JSF::Forms::FormBuilder.example('file_input'))

    #   field['items']['pattern'] = regex_str

    #   refute_empty field.errors
    # end

    # %w[
    #   ^http.+\.?(?:)$
    #   ^http.+\.?(?:asdf)$
    #   ^http.+\.?(?:asdf|asdf)$
    # ].each do |regex_str|
    #   field = JSF::Forms::Field::FileInput.new(JSF::Forms::FormBuilder.example('file_input'))

    #   field['items']['pattern'] = regex_str

    #   assert_empty field.errors
    # end

    # test specific use case
    %w[
      ^http.+\.?(?:|)$
      ^http.+\.?(?:aa)$
      ^http.+\.?(?:heic)$
    ].each do |regex_str|
      field = JSF::Forms::Field::FileInput.new(JSF::Forms::FormBuilder.example('file_input'))

      field['items']['pattern'] = regex_str

      refute_empty field.errors
    end

    %w[
      ^http.+\.?(?:)$
      ^http.+\.?(?:pdf)$
      ^http.+\.?(?:heic|heif|jpeg|jpg|png)$
    ].each do |regex_str|
      field = JSF::Forms::Field::FileInput.new(JSF::Forms::FormBuilder.example('file_input'))

      field['items']['pattern'] = regex_str

      assert_empty field.errors
    end
  end

end