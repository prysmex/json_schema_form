require 'json_schema_form_test_helper'

class ValidatableTest < Minitest::Test
  include JsonSchemaFormTestHelper::SampleClassHooks

  # Used to test validations
  module IdValidation
    def own_errors(passthru={})
      errors_hash = {}
      errors_hash[:$id] = 'id must be present' if self[:$id].nil?
      errors_hash
    end
  end

  def setup
    super
    @sample_schema_class.include JSF::Core::Buildable
    @sample_schema_class.include JSF::Validations::Validatable
  end

  # errors

  def test_errors_raises_no_method_error_when_own_errors_not_defined
    assert_raises(NoMethodError){ SampleSchema.new({}).errors }
  end

  def test_errors_has_own_errors
    SampleSchema.include IdValidation
    refute_nil SampleSchema.new({}).errors[:$id]
    assert_nil SampleSchema.new({'$id': 'some_id'}).errors[:$id]
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
    refute_nil schema.errors.dig(:allOf, 0, :properties, :prop_1, :$id)
    schema[:allOf].first[:properties][:prop_1][:$id] = 'some_id'
    assert_empty schema.errors
  end

  # own_errors

  def test_own_errors_raises_error_when_not_defiend
    assert_raises(NoMethodError){ SampleSchema.new({}).own_errors }
  end

end