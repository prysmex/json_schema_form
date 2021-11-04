require 'json_schema_form_test_helper'

class FormTest < Minitest::Test

  #############
  #validations#
  #############

  def test_no_unknown_keys_allowed
    errors = JSF::Forms::Form.new({array_key: [], other_key: 1}).errors
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]
  end

  # @todo
  # conditional fields
  def test_property_key_must_match_property_id
    form_example = JSF::Forms::FormBuilder.example('form')
    form = JSF::Forms::FormBuilder.build(form_example) do
      append_property :header_1, example('header').merge({:$id => '#/properties/header_1'})
    end
    assert_empty form.errors
    form[:properties][:header_1][:$id] = '#/_properties/header_1'
    refute_empty form.errors
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

  def test_components_only_in_root
    form = JSF::Forms::FormBuilder.build() do
      append_property(:switch1, example('switch'))
      add_component_pair(db_id: 1, index: 0)
    end
    
    assert_empty form.errors

    form.append_conditional_property(:component_2, JSF::Forms::FormBuilder.example('component'), dependent_on: :switch1, type: :const, value: true)
    refute_empty form.errors(skip: [:component_presence]).dig(:allOf, 0, :then, :base)
  end

  def test_property_response_sets_must_exist
    form = JSF::Forms::FormBuilder.build() do
      append_property(:select1, example('select')).tap do |field|
        field.response_set_id = :response_set_1
      end
    end

    refute_empty form.errors
    form.add_response_set(:response_set_1, JSF::Forms::FormBuilder.example('response_set'))
    assert_empty form.errors
  end

  def test_conditional_fields_whitelist
    form = JSF::Forms::FormBuilder.build() do
      append_property(:text_input1, example('text_input')) # cannot have conditional
      append_property(:switch1, example('switch'))
      append_conditional_property :dependent_text_input1, example('text_input'), dependent_on: :switch1, type: :const, value: true
    end

    assert_empty form.errors
    form.append_conditional_property(:dependent_text_input2, JSF::Forms::FormBuilder.example('text_input'), dependent_on: :text_input1, type: :const, value: true)
    refute_empty form.errors
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

  ############
  #transforms#
  ############

  def test_transform
    form = JSF::Forms::FormBuilder.build() do
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

    # test all field types
    form[:properties].each do |name, field|
      classified_name = name.to_s.split('_').collect(&:capitalize).join
      assert_instance_of Object.const_get("JSF::Forms::Field::#{classified_name}"), field
    end

    # test definitions
    assert_instance_of JSF::Forms::Form, form[:definitions][:form1]
    assert_instance_of JSF::Forms::ResponseSet, form[:definitions][:response_set_1]
    assert_instance_of JSF::Forms::ComponentRef, form[:definitions][JSF::Forms::Form.component_ref_key(1)]

    # test allOf
    assert_instance_of JSF::Schema, form[:allOf].first
    assert_instance_of JSF::Schema, form[:allOf].first[:if]
    assert_instance_of JSF::Schema, form[:allOf].first[:if][:properties][:select]

    # test then
    assert_instance_of JSF::Forms::Form, form[:allOf].first[:then]

    # nested properties
    assert_instance_of JSF::Forms::Field::Checkbox, form[:allOf].first[:then][:properties][:checkbox2]
  end

  ##############
  ###METHODS####
  ##############

  # def test_component_definitions
  # end

  # def add_component_definition
  # end

  # def remove_component_definition
  # end

  # def test_response_sets
  # end

  # def test_add_response_set
  # end

  # def test_properties
  # end

  # def test_dynamic_properties
  # end

  # def test_merged_properties
  # end

  # def test_get_property
  # end

  # def test_get_dynamic_property
  # end

  # def test_get_merged_property
  # end

  # def test_prepend_property
  # end

  # def test_append_property
  # end

  # def test_insert_property_at_index
  # end

  # def test_move_property
  # end

  # def test_min_sort
  # end

  # def test_max_sort
  # end

  # def test_get_property_by_sort
  # end

  # def test_verify_sort_order
  # end

  # def test_sorted_properties
  # end

  # def test_resort!
  # end

  def test_get_condition

    form = JSF::Forms::FormBuilder.build() do
      append_property(:prop1, example('select'))
      add_or_get_condition('prop1', :const, 'const')
      add_or_get_condition('prop1', :not_const, 'not_const')
      add_or_get_condition('prop1', :enum, ['enum'])
      add_or_get_condition('prop1', :not_enum, ['not_enum'])
    end

    assert_equal 'const', form.get_condition(:prop1, :const, 'const')&.dig(:if, :properties, :prop1, :const)
    assert_equal 'not_const', form.get_condition(:prop1, :not_const, 'not_const')&.dig(:if, :properties, :prop1, :not, :const)
    assert_equal 'enum', form.get_condition(:prop1, :enum, 'enum')&.dig(:if, :properties, :prop1, :enum)&.first
    assert_equal 'not_enum', form.get_condition(:prop1, :not_enum, 'not_enum')&.dig(:if, :properties, :prop1, :not, :enum)&.first

    assert_nil form.get_condition(:prop1, :const, 'other_value')
  end

  # def test_add_or_get_condition
  # end

  # def test_insert_conditional_property_at_index
  # end

  # def test_append_conditional_property
  # end

  # def test_prepend_conditional_property
  # end

  # def test_schema_form_iterator
  # end

  # def test_max_score
  # end

  # def test_i18n_document
  # end

  # def test_i18n_document_value
  # end

  # def test_nil_document
  # end

  # def test_compile!
  # end

  # def test_migrate!
  # end

end