require 'json_schema_form_test_helper'

class FormTest < Minitest::Test

  ############
  #transforms#
  ############

  def test_transform
    form = JSF::Forms::FormBuilder.build() do
      # definitions
      add_response_set(:response_set_1, example('response_set'))
      add_component_ref(db_id: 1)
      add_definition('form1', JSF::Forms::FormBuilder.example('form'))

      # properties
      append_property(:checkbox, example('checkbox'))
      append_property(:component, example('component'))
      append_property(:date_input, example('date_input'))
      append_property(:file_input, example('file_input'))
      append_property(:header, example('header'))
      append_property(:info, example('info'))
      append_property(:number_input, example('number_input'))
      append_property(:select, example('select'))
      append_property(:slider, example('slider'))
      append_property(:static, example('static'))
      append_property(:text_input, example('text_input'))

      # conditional properties
      append_conditional_property(:checkbox2, example('checkbox'), dependent_on: :select, type: :const, value: 1)
    end

    # definitions
    assert_instance_of JSF::Forms::Form, form[:definitions][:form1]
    assert_instance_of JSF::Forms::ResponseSet, form[:definitions][:response_set_1]
    assert_instance_of JSF::Forms::ComponentRef, form[:definitions][JSF::Forms::Form.component_ref_key(1)]

    # all field types
    form[:properties].each do |name, field|
      classified_name = name.to_s.split('_').collect(&:capitalize).join
      assert_instance_of Object.const_get("JSF::Forms::Field::#{classified_name}"), field
    end

    # allOf
    assert_instance_of JSF::Schema, form[:allOf].first
    assert_instance_of JSF::Schema, form[:allOf].first[:if]
    assert_instance_of JSF::Schema, form[:allOf].first[:if][:properties][:select]

    # then
    assert_instance_of JSF::Forms::Form, form[:allOf].first[:then]

    # properties inside allOf then
    assert_instance_of JSF::Forms::Field::Checkbox, form[:allOf].first[:then][:properties][:checkbox2]
  end

  #############
  #validations#
  #############

  # errors

  def test_no_unknown_keys_allowed
    errors = JSF::Forms::Form.new({array_key: [], other_key: 1}).errors
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]
  end

  def test_component_presence_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :component_presence }
    form = JSF::Forms::FormBuilder.build do
      add_component_pair(db_id: 1, index: :prepend)
    end

    # no errors
    assert_empty form.errors(if: error_proc)

    # missmatch id
    form[:definitions][:shared_schema_template_1].db_id = 2
    refute_empty form.errors(if: error_proc)

    # not present
    form[:properties] = {}
    refute_empty form.errors(if: error_proc)
  end

  def test_match_key_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :match_key }

    # in root schema
    form = JSF::Forms::FormBuilder.build() do
      append_property :switch_1, example('switch').merge({:$id => '#/properties/switch_1'})
    end
    assert_empty form.errors(if: error_proc)
    form.dig(:properties, :switch_1)[:$id] = '#/properties/__switch_1'
    refute_empty form.errors(if: error_proc)

    # nested
    form = JSF::Forms::FormBuilder.build() do
      append_property :switch_1, example('switch').merge({:$id => '#/properties/switch_1'})
      append_conditional_property(:switch_2, example('switch').merge({:$id => '#/properties/switch_2'}), dependent_on: :switch_1, type: :const, value: true)
    end
    assert_empty form.errors(if: error_proc)
    form.dig(:allOf, 0, :then, :properties, :switch_2)[:$id] = '#/properties/__switch_2'
    refute_empty form.errors(if: error_proc)
  end

  def test_response_set_presence_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :response_set_presence }

    form = JSF::Forms::FormBuilder.build() do
      append_property(:select1, example('select')).tap do |field|
        field.response_set_id = :response_set_1
      end
    end

    refute_empty form.errors(if: error_proc)
    form.add_response_set(:response_set_1, JSF::Forms::FormBuilder.example('response_set'))
    assert_empty form.errors(if: error_proc)
  end

  def test_component_in_root_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :component_in_root }
    form = JSF::Forms::FormBuilder.build() do
      append_property(:switch1, example('switch'))
      add_component_pair(db_id: 1, index: 0)
    end
    
    assert_empty form.errors(if: error_proc)

    form.append_conditional_property(:component_2, JSF::Forms::FormBuilder.example('component'), dependent_on: :switch1, type: :const, value: true)
    refute_empty form.errors(if: error_proc).dig(:allOf, 0, :then, :base)
  end

  def test_component_ref_presence_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :component_ref_presence }
    db_id = 1

    form = JSF::Forms::FormBuilder.build() do
      append_property(:component_1, example('component')).tap{|c| c.db_id=db_id}
    end

    refute_empty form.errors(if: error_proc)
    form.add_component_ref(db_id: db_id)
    assert_empty form.errors(if: error_proc)
  end

  # @todo test more fields?
  def test_conditional_fields_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :conditional_fields }
    form = JSF::Forms::FormBuilder.build() do
      append_property(:text_input1, example('text_input')) # cannot have conditional
      append_property(:switch1, example('switch'))
      append_conditional_property :dependent_text_input1, example('text_input'), dependent_on: :switch1, type: :const, value: true
    end

    assert_empty form.errors(if: error_proc)
    form.append_conditional_property(:dependent_text_input2, JSF::Forms::FormBuilder.example('text_input'), dependent_on: :text_input1, type: :const, value: true)
    refute_empty form.errors(if: error_proc)
  end

  def test_valid_subschema_form
    form = JSF::Forms::Form.new(
      {
        "required": [],
        "properties": {},
        "allOf": [],
      },
      meta: {
        is_subschema: true
      }
    )
    assert_empty form.errors
  end

  # valid_for_locale?

  def test_not_valid_for_locale_when_field_is_not_valid
    form = JSF::Forms::FormBuilder.build do
      append_property :prop1, JSF::Forms::FormBuilder.example('info')
    end

    assert_equal true, form.valid_for_locale?
    form.get_property(:prop1).set_label_for_locale(nil)
    assert_equal false, form.valid_for_locale?
  end

  def test_not_valid_for_locale_when_conditional_field_is_not_valid
    form = JSF::Forms::FormBuilder.build do
      append_property :switch1, JSF::Forms::FormBuilder.example('switch')
      append_conditional_property :dependent_info, example('info'), dependent_on: :switch1, type: :const, value: true
    end

    assert_equal true, form.valid_for_locale?
    form.get_dynamic_property(:dependent_info).set_label_for_locale(nil)
    assert_equal false, form.valid_for_locale?
  end

  def test_not_valid_for_locale_when_response_set_invalid
    form = JSF::Forms::FormBuilder.build do
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :default))
      end

      append_property(:select1, example('select'), {required: true}).tap do |field|
        field.response_set_id = :response_set_1
      end
    end

    assert_equal true, form.valid_for_locale?
    form.response_sets[:response_set_1][:anyOf].each{|r| r.set_translation(nil) }
    assert_equal false, form.valid_for_locale?
  end

  def test_valid_for_locale_when_invalid_unused_response_set
    form = JSF::Forms::FormBuilder.build do
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :default))
      end
    end
    assert_equal true, form.valid_for_locale?
    form.response_sets[:response_set_1][:anyOf].each{|r| r.set_translation(nil) }
    assert_equal false, form.response_sets[:response_set_1].valid_for_locale?
  end

  ##############
  ###METHODS####
  ##############

  def test_component_definitions
    form = JSF::Forms::FormBuilder.build do
      add_component_ref(db_id: 1)
      add_definition(:some_key, JSF::Forms::Form.new)
    end
    assert_equal ["shared_schema_template_1", "some_key"], form.component_definitions.keys
  end

  def test_add_component_ref
    form = JSF::Forms::FormBuilder.build do
      add_component_ref(db_id: 1)
    end

    assert_equal true, form['definitions'].one?{|k,v| v.is_a?(JSF::Forms::ComponentRef) }
  end

  def test_get_component_ref
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_component_ref(db_id: db_id)
    end

    assert_instance_of JSF::Forms::ComponentRef, form.get_component_ref(db_id: db_id)
  end

  def test_remove_component_ref
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_component_ref(db_id: db_id)
    end

    form.remove_component_ref(db_id: db_id)

    assert_empty form['definitions']
  end

  def test_add_component_pair
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_component_pair(db_id: db_id, index: :append)
    end

    component_ref = form.get_component_ref(db_id: db_id)
    assert_instance_of JSF::Forms::ComponentRef, component_ref
    assert_instance_of JSF::Forms::Field::Component, component_ref&.component
  end

  def test_remove_component_pair
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_component_pair(db_id: db_id, index: :append)
      remove_component_pair(db_id: db_id)
    end

    assert_empty form['definitions']
    assert_empty form['properties']
  end

  # def test_response_sets
  #   form = JSF::Forms::FormBuilder.build do
  #     add_response_set('some_key', )
  #   end
  # end

  # def test_get_condition

  #   form = JSF::Forms::FormBuilder.build() do
  #     append_property(:prop1, example('select'))
  #     add_or_get_condition('prop1', :const, 'const')
  #     add_or_get_condition('prop1', :not_const, 'not_const')
  #     add_or_get_condition('prop1', :enum, ['enum'])
  #     add_or_get_condition('prop1', :not_enum, ['not_enum'])
  #   end

  #   assert_equal 'const', form.get_condition(:prop1, :const, 'const')&.dig(:if, :properties, :prop1, :const)
  #   assert_equal 'not_const', form.get_condition(:prop1, :not_const, 'not_const')&.dig(:if, :properties, :prop1, :not, :const)
  #   assert_equal 'enum', form.get_condition(:prop1, :enum, 'enum')&.dig(:if, :properties, :prop1, :enum)&.first
  #   assert_equal 'not_enum', form.get_condition(:prop1, :not_enum, 'not_enum')&.dig(:if, :properties, :prop1, :not, :enum)&.first

  #   assert_nil form.get_condition(:prop1, :const, 'other_value')
  # end

end