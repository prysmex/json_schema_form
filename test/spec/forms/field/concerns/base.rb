require 'test_helper'
require_relative 'field_example_helpers'

#
# Some of the methods added by JSF::Forms::Field::Concerns::Base may be overriden on a field class,
# for example, `valid_for_locale?`. If that is the case, those methods should also be overriden on the
# specific field specs file
#
module BaseFieldTests

  include FieldExampleHelpers

  ##################
  ###VALIDATIONS####
  ##################

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

    errors = tested_klass.new({array_key: [], other_key: 1}).errors(if: error_proc)
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

  # def test_hidden_and_required
  #   example = self.tested_klass_example
  #   prop = nil

  #   JSF::Forms::FormBuilder.build do
  #     prop = append_property(:prop1, example, {required: true}).tap do |field|
  #       field.hidden = true
  #     end
  #   end

  #   refute_empty prop.errors(if: ->(obj, key) { key == :hidden_and_required })
  # end

  # def test_hide_on_create_and_required
  #   example = self.tested_klass_example
  #   prop = nil

  #   JSF::Forms::FormBuilder.build do
  #     prop = append_property(:prop1, example, {required: true}).tap do |field|
  #       field.hideOnCreate = true
  #     end
  #   end

  #   refute_empty prop.errors(if: ->(obj, key) { key == :hide_on_create_and_required })
  # end

  def test_verify_default
    example = self.tested_klass_example
    prop = tested_klass.new(example)

    return unless prop.key?('type')

    # ensure never matches
    prop['default'] = case prop['type']
    when 'array'
      {}
    else 
      []
    end

    refute_empty prop.errors(if: ->(obj, key) { key == :verify_default })
  end

  ##############
  ###METHODS####
  ##############

  def test_scored?
    instance = tested_klass.new(self.tested_klass_example)
    assert_equal false, instance.scored?
  end

  # def test_legalized?
  # end

end