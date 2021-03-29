require 'json_schema_form_test_helper'

module FieldHelpers

  def field_klass_name
    self.class.name.sub('Test', '')
  end

  def field_klass
    Object.const_get("SchemaForm::Field::#{field_klass_name}")
  end

  def example_for_current_field_klass
    underscored_klass_name = field_klass_name.split(/(?=[A-Z])/).map(&:downcase).join('_')
    JsonSchemaForm::SchemaFormExamples.send(underscored_klass_name)
  end

end

module BaseMethodsTests

  include FieldHelpers
  
  def test_i18n_label
    example = self.example_for_current_field_klass
    instance = field_klass.new(example)
    instance.set_label_for_locale('some_label')
    assert_equal 'some_label', instance.i18n_label
  end

  def test_valid_for_locale
    klass = field_klass

    if [SchemaForm::Field::Static, SchemaForm::Field::Switch, SchemaForm::Field::Slider].include?(klass)
      skip "Does not apply for klass #{klass}"
    end

    example = self.example_for_current_field_klass
    instance = field_klass.new(example)

    instance.set_label_for_locale('opciones')
    assert_equal true, instance.valid_for_locale?(:es)

    instance.set_label_for_locale('')
    assert_equal false, instance.valid_for_locale?(:es)

    instance.set_label_for_locale(nil)
    assert_equal false, instance.valid_for_locale?(:es)

    assert_equal false, instance.valid_for_locale?(:random)
  end

  def test_errors_dont_raise_error
    field_klass.new().errors
    assert_equal true, true
  end

end

module ResponseSettableTests

  include FieldHelpers
  
  def test_response_set_id
    example = self.example_for_current_field_klass
    instance = field_klass.new(example)
    assert_equal '#/definitions/__test_response_set_id__', instance.response_set_id
  end
  
  def test_response_set
    example_form = JsonSchemaForm::SchemaFormExamples.form
    field_example = self.example_for_current_field_klass
    field_instance = field_klass.new(field_example, {parent: example_form})
    
    example_form[:properties][:testprop] = field_instance
    example_form[:definitions][:__test_response_set_id__] = {}

    refute_nil example_form[:properties][:testprop].response_set
  end

  def test_i18n_value
    example_form = JsonSchemaForm::SchemaFormExamples.form
    field_example = self.example_for_current_field_klass
    field_instance = field_klass.new(field_example, parent: example_form)

    example_form[:properties][:testprop] = field_instance
    example_form[:definitions][:__test_response_set_id__] = SchemaForm::ResponseSet.new({
      anyOf: [
        {
          const: 'test',
          displayProperties: {
            i18n: {
              en: "score_1_en",
              es: "score_1_es"
            }
          }
        }
      ]
    })

    assert_equal 'score_1_en', example_form[:properties][:testprop].i18n_value('test', :en)
  end

end