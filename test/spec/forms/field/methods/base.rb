require 'test_helper'
require_relative 'field_example_helpers'

class FormTest < Minitest::Test

  def test_document_path
    form = JSF::Forms::FormBuilder.build() do

      # Add form in definitions
      add_component_pair(
        db_id: 1,
        index: :prepend,
        definition: JSF::Forms::FormBuilder.build() do
          append_property(:shared_switch_1, example('switch'))
          append_conditional_property(:shared_switch_1_1, example('switch'), dependent_on: :shared_switch_1, type: :const, value: true)
        end
      )

      # Section
      append_property(:section, example('section')).tap do |section|
        section.form.append_property(:switch_2, example('switch'))
      end

      # Field
      append_property(:switch_1, example('switch'))

      # Dynamic Field
      append_conditional_property(:switch_1_1, example('switch'), dependent_on: :switch_1, type: :const, value: true) do |f, field|
        f.append_conditional_property(:switch_1_2, example('switch'), dependent_on: :switch_1_1, type: :const, value: true) do |f, field|
        end
      end
      
    end

    assert_equal ["switch_1"], form.dig(:properties, :switch_1).document_path
    assert_equal ["switch_1_1"], form.dig(:allOf, 0, :then, :properties, :switch_1_1).document_path
    assert_equal ["section", "switch_2"], form.dig(:properties, :section, :items, :properties, :switch_2).document_path
    assert_equal ["shared_schema_template_1", "shared_switch_1"], form.dig(:definitions, :shared_schema_template_1, :properties, :shared_switch_1).document_path
    assert_equal ["shared_schema_template_1", "shared_switch_1_1"], form.dig(:definitions, :shared_schema_template_1, :allOf,  0, :then, :properties, :shared_switch_1_1).document_path
  end

end

#
# Some of the methods added by JSF::Forms::Field::Methods::Base may be overriden on a field class,
# for example, `valid_for_locale?`. If that is the case, those methods should also be overriden on the
# specific field specs file
#
module BaseMethodsTests

  include FieldExampleHelpers

  ##################
  ###VALIDATIONS####
  ##################

  # valid_for_locale?

  # overriden in Static, Switch, Slider
  def test_valid_for_locale
    example = self.tested_klass_example
    instance = tested_klass.new(example)

    instance.set_label_for_locale('opciones')
    assert_equal true, instance.valid_for_locale?

    instance.set_label_for_locale('')
    assert_equal false, instance.valid_for_locale?

    instance.set_label_for_locale(nil)
    assert_equal false, instance.valid_for_locale?

    assert_equal false, instance.valid_for_locale?(:random)
  end

  # validation_schema

  def test_no_unknown_keys_allowed
    error_proc = ->(obj, key) { obj.is_a?(tested_klass) && key == :schema }

    errors = tested_klass.new({array_key: [], other_key: 1}).errors
    # unknown keys
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]
    # required keys
    refute_nil errors[:displayProperties]
  end

  def test_id_regex
    assert_nil tested_klass.new({'$id': '#/properties/hello_10-wow'}).errors[:'$id']
    refute_nil tested_klass.new({'$id': '/definitions/hello'}).errors[:'$id']
    refute_nil tested_klass.new({'$id': '#/definitions/hello'}).errors[:'$id']
  end
  
  # other

  def test_hide_on_create_and_required
    example = self.tested_klass_example
    prop = nil

    JSF::Forms::FormBuilder.build do
      prop = append_property(:prop1, example, {required: true}).tap do |field|
        field.hideOnCreate = true
      end
    end
    
    refute_empty prop.errors(if: ->(obj, key) { key == :hidden_and_required })
  end

  ##############
  ###METHODS####
  ##############

  def test_scored?
    instance = tested_klass.new(self.tested_klass_example)
    assert_equal false, instance.scored?
  end

end