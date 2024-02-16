require 'test_helper'

class ValidatableTest < Minitest::Test
  include TestHelper::SampleClassHooks

  # Used to test validations
  module IdValidation
    def errors(**passthru)
      errors_hash = super
      if run_validation?(passthru, :id_presence)
        errors_hash[:$id] = 'id must be present' if self[:$id].nil?
      end
      errors_hash
    end
  end

  def setup
    super
    @sample_schema_class.include JSF::Core::Buildable
    @sample_schema_class.include JSF::Validations::Validatable
  end

  # errors

  def test_errors
    SampleSchema.include IdValidation
    refute_nil SampleSchema.new({}).errors[:$id]
    assert_nil SampleSchema.new({'$id': 'some_id'}).errors[:$id]

    # with proc
    refute_nil SampleSchema.new({'$id': 'some_id'}).errors(
      proc: ->(errors) {
        add_error_on_path(
          errors,
          ['base'],
          'something custom'
        )
      }
    )['base']
  end

  def test_has_subschema_errors
    SampleSchema.include IdValidation
    schema = SampleSchema.new({
      '$id': 'some_id',
      allOf: [
        {
          '$id': 'some_id',
          properties: {
            prop_1: {}      # no $id
          }
        }
      ]
    })

    # recursive errors
    refute_nil schema.errors.dig(:allOf, 0, :properties, :prop_1, :$id)

    # not recursive
    assert_nil schema.errors(recursive: false).dig(:allOf, 0, :properties, :prop_1, :$id)

    # fix error
    schema[:allOf].first[:properties][:prop_1][:$id] = 'some_id'

    assert_empty schema.errors
  end

  def test_conditional_errors
    SampleSchema.include IdValidation
    refute_empty SampleSchema.new({}).errors

    # if
    refute_empty SampleSchema.new({}).errors(if: ->(instance, key){key == :id_presence})
    assert_empty SampleSchema.new({}).errors(if: ->(instance, key){key != :id_presence})
    
    # unless
    assert_empty SampleSchema.new({}).errors(unless: ->(instance, key){key == :id_presence})
    refute_empty SampleSchema.new({}).errors(unless: ->(instance, key){key != :id_presence})
  end

  # methods

  # add_error_on_path
  def test_add_error_on_path
    hash = {}
    path = [:some, :new, :path]
    schema = SampleSchema.new()

    # create new path
    schema.send(:add_error_on_path, hash, path, 'some_error')
    assert_equal 'some_error', hash.dig(*path)[0]

    # append error
    schema.send(:add_error_on_path, hash, path, 'other_error')
    assert_equal 'other_error', hash.dig(*path)[1]
  end

  # # key_contains?
  # def test_key_contains?
  #   hash = {some_key: ['value']}
  #   schema = SampleSchema.new()

  #   assert_equal true, schema.send(:key_contains?, hash, :some_key, 'value')
  #   assert_equal false, schema.send(:key_contains?, hash, :some_key, 'other_value')
  #   assert_equal false, schema.send(:key_contains?, hash, :other_key, 'value')
  # end

  # run_validation?
  # def test_run_validation?
  # end

end