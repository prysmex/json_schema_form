require 'json_schema_form_test_helper'

module FieldHelpers

  def field_klass_name
    self.class.name.sub('Test', '')
  end

  def field_klass
    Object.const_get("SchemaForm::Field::#{field_klass_name}")
  end

  def underscored_klass_name
    field_klass_name.split(/(?=[A-Z])/).map(&:downcase).join('_')
  end

  def example_for_current_field_klass
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
    assert_equal true, instance.valid_for_locale?

    instance.set_label_for_locale('')
    assert_equal false, instance.valid_for_locale?

    instance.set_label_for_locale(nil)
    assert_equal false, instance.valid_for_locale?

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
    name = self.underscored_klass_name
    prop = nil
    SchemaForm::FormBuilder.build() do
      add_response_set(:__test_response_set_id__, example('response_set'))
      prop = append_property(:testprop, example(name))
    end

    refute_nil prop.response_set
  end

  def test_i18n_value
    name = self.underscored_klass_name
    prop = nil
    SchemaForm::FormBuilder.build() do
      add_response_set(:__test_response_set_id__, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :default)).tap do |r|
          r[:const] = 'test'
          r[:displayProperties] = { i18n: { es: "score_1_es" } }
        end
      end
      prop = append_property(:testprop, example(name))
    end

    assert_equal 'score_1_es', prop.i18n_value('test', :es)
  end

end