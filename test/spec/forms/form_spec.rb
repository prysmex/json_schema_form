require 'test_helper'

class FormTest < Minitest::Test

  ############
  #transforms#
  ############

  def test_transform
    form = JSF::Forms::FormBuilder.build() do
      # definitions
      add_response_set(:response_set_1, example('response_set'))
      add_component_definition(db_id: 1)
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
    assert_instance_of JSF::Forms::Condition, form[:allOf].first
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

  def test_schema_key_validations
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :schema }

    form = JSF::Forms::Form.new({array_key: [], other_key: 1})
    form.delete('type')

    errors = form.errors(if: error_proc)
    # unknown keys
    refute_nil errors[:array_key]
    refute_nil errors[:other_key]
    # required keys
    refute_nil errors[:type]
  end

  def test_sorting_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :sorting }
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
      append_property(:switch_3, example('switch'))
    end

    assert_empty form.errors(if: error_proc)
    form.get_property(:switch_2).sort = 4
    refute_empty form.errors(if: error_proc)
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
    form.add_component_definition(db_id: db_id)
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
  
  # ToDo move this to Condition spec?
  def test_conditions_format
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Condition) && key == :schema }
    form = JSF::Forms::FormBuilder.build() do
      append_property(:switch1, example('switch'))
      append_conditional_property :dependent_text_input1, example('text_input'), dependent_on: :switch1, type: :const, value: true
    end

    assert_empty form.errors(if: error_proc)

    # unexpeceted root key
    new_form = form.deep_dup
    new_form['allOf'][0]['invalid_key'] = {}
    refute_empty new_form.errors(if: error_proc)

    # unexpeceted if key
    new_form = form.deep_dup
    new_form['allOf'][0]['if']['invalid_key'] = {}
    refute_empty new_form.errors(if: error_proc)
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
    form.get_merged_property(:dependent_info).set_label_for_locale(nil)
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
      add_component_definition(db_id: 1)
      add_definition(:some_key, JSF::Forms::Form.new)
    end
    assert_equal ["shared_schema_template_1", "some_key"], form.component_definitions.keys
  end

  def test_add_component_definition
    form = JSF::Forms::FormBuilder.build do
      add_component_definition(db_id: 1)
    end

    assert_equal true, form['definitions'].one?{|k,v| v.is_a?(JSF::Forms::ComponentRef) }
  end

  def test_get_component_definition
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_component_definition(db_id: db_id)
    end

    assert_instance_of JSF::Forms::ComponentRef, form.get_component_definition(db_id: db_id)
  end

  def test_remove_component_definition
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_component_definition(db_id: db_id)
    end

    form.remove_component_definition(db_id: db_id)

    assert_empty form['definitions']
  end

  def test_add_component_pair
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_component_pair(db_id: db_id, index: :append)
    end

    component_ref = form.get_component_definition(db_id: db_id)
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

  # def test_add_response_set
  # end

  def test_properties
    form = JSF::Forms::FormBuilder.build
    assert_same form.properties, form[:properties]
  end

  def test_merged_properties
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))

      # conditional properties
      append_conditional_property(:switch_2, example('switch'), dependent_on: :switch_1, type: :const, value: true) do |form, field|
        form.append_conditional_property(:switch_3, example('switch'), dependent_on: :switch_2, type: :const, value: true) do |form, field|
          form.append_conditional_property(:switch_4, example('switch'), dependent_on: :switch_3, type: :const, value: true)
        end
      end
    end
    
    assert_equal ['switch_1', 'switch_2', 'switch_3', 'switch_4'], form.merged_properties.keys
    assert_equal ['switch_2', 'switch_3', 'switch_4'], form.merged_properties(start_level: 1).keys
    assert_equal ['switch_2'], form.merged_properties(start_level: 1, levels: 1).keys
  end

  def test_get_property
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
    end

    refute_nil form.get_property('switch_1')
  end

  def test_get_merged_property
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_conditional_property(:switch_2, example('switch'), dependent_on: :switch_1, type: :const, value: true)
    end

    assert_instance_of JSF::Forms::Field::Switch, form.get_merged_property('switch_1')
    assert_instance_of JSF::Forms::Field::Switch, form.get_merged_property('switch_2')
  end

  def test_prepend_property
    form = JSF::Forms::FormBuilder.build do
      prepend_property(:switch_1, example('switch'))
      prepend_property(:switch_2, example('switch'))
    end

    assert_equal 1, form.get_property('switch_1').sort
    assert_equal 0, form.get_property('switch_2').sort
  end

  def test_append_property
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
    end

    assert_equal 0, form.get_property('switch_1').sort
    assert_equal 1, form.get_property('switch_2').sort
  end

  def test_insert_property_at_index
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
      insert_property_at_index(1, :switch_3, example('switch'))
    end

    # sort
    assert_equal 0, form.get_property('switch_1').sort
    assert_equal 2, form.get_property('switch_2').sort
    assert_equal 1, form.get_property('switch_3').sort
  end

  def test_remove_property
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
      remove_property(:switch_1)
    end

    assert_nil form.get_property('switch_1')
    assert_equal 0, form.get_property('switch_2').sort
  end

  def test_move_property
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
      append_property(:switch_3, example('switch'))
      move_property(:switch_3, 0)
    end

    assert_equal 1, form.get_property('switch_1').sort
    assert_equal 2, form.get_property('switch_2').sort
    assert_equal 0, form.get_property('switch_3').sort
  end

  def test_min_sort
    form = JSF::Forms::FormBuilder.build
    assert_nil form.min_sort

    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
    end
    assert_equal 0, form.min_sort
  end

  def test_max_sort
    form = JSF::Forms::FormBuilder.build
    assert_nil form.max_sort

    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
    end
    assert_equal 1, form.max_sort
  end

  def test_get_property_by_sort 
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
    end
    assert_same form.get_property(:switch_1), form.get_property_by_sort(0)
  end

  def test_verify_sort_order
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
    end

    assert_equal true, form.verify_sort_order
    form.get_property(:switch_1).sort = 3
    assert_equal false, form.verify_sort_order
  end

  def test_sorted_properties
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
      append_property(:switch_3, example('switch'))
      move_property(:switch_3, 0)
    end

    assert_equal ['switch_3', 'switch_1', 'switch_2'], form.sorted_properties.map(&:key_name)
  end

  def test_resort!
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
      append_property(:switch_2, example('switch'))
      append_property(:switch_3, example('switch'))
    end

    # change sort to be non consecutive and in different order
    form.get_property(:switch_1).sort = 20
    form.get_property(:switch_2).sort = 10
    form.get_property(:switch_3).sort = 30

    form.resort!
    assert_equal 1, form.get_property('switch_1').sort
    assert_equal 0, form.get_property('switch_2').sort
    assert_equal 2, form.get_property('switch_3').sort
  end

  def test_get_condition
    form = JSF::Forms::FormBuilder.build() do
      append_property(:prop1, example('select'))
      add_condition('prop1', :const, 'const')
      add_condition('prop1', :not_const, 'not_const')
      add_condition('prop1', :enum, ['enum'])
      add_condition('prop1', :not_enum, ['not_enum'])
    end

    # found
    assert_equal 'const', form.get_condition(:prop1, :const, 'const')&.dig(:if, :properties, :prop1, :const)
    assert_equal 'not_const', form.get_condition(:prop1, :not_const, 'not_const')&.dig(:if, :properties, :prop1, :not, :const)
    assert_equal 'enum', form.get_condition(:prop1, :enum, 'enum')&.dig(:if, :properties, :prop1, :enum)&.first
    assert_equal 'not_enum', form.get_condition(:prop1, :not_enum, 'not_enum')&.dig(:if, :properties, :prop1, :not, :enum)&.first

    # not found
    assert_nil form.get_condition(:prop1, :const, 'other_value')

    # invalid key
    assert_raises(ArgumentError){ form.get_condition(:prop1, :wrong_key, 'other_value') }
  end

  def test_add_condition
    form = JSF::Forms::FormBuilder.build() do
      append_property(:switch_1, example('switch'))
    end

    # add new condition
    condition = form.add_condition('switch_1', :const, true)
    assert_instance_of JSF::Forms::Condition, condition

    # invalid key
    assert_raises(ArgumentError){ form.add_condition(:prop1, :wrong_key, true) }

    # non-existing prop
    assert_raises(ArgumentError){ form.add_condition(:other_prop, :const, true) }
  end

  def test_insert_conditional_property_at_index

    # raises error when field does not exist
    assert_raises (ArgumentError) do
      JSF::Forms::FormBuilder.build() do
        insert_conditional_property_at_index(0, :switch_2, example('switch'), dependent_on: :switch_1, type: :const, value: true)
      end
    end

    # correct sorting
    form = JSF::Forms::FormBuilder.build() do
      append_property(:switch_1, example('switch'))
      insert_conditional_property_at_index(0, :switch_2, example('switch'), dependent_on: :switch_1, type: :const, value: true)
      insert_conditional_property_at_index(0, :switch_3, example('switch'), dependent_on: :switch_1, type: :const, value: true)  do |f, field|
        f.insert_conditional_property_at_index(1, :switch_4, example('switch'), dependent_on: :switch_2, type: :const, value: true)
      end
    end
    assert_equal 0, form.get_property('switch_1').sort
    assert_equal 1, form.get_merged_property('switch_2').sort
    assert_equal 0, form.get_merged_property('switch_3').sort

    # added conditions are valid
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :conditions_format }
    assert_empty form.errors(if: error_proc)

    # supports yielding block
    refute_empty form.dig('allOf', 0, 'then', 'allOf', 0, 'then', 'properties', 'switch_4')
  end

  # def test_append_conditional_property
  # end

  # def test_prepend_conditional_property
  # end

  # def test_is_component_definition?
  # end

  def test_each_form
    form1, form2 = form3 = nil
    form1 = JSF::Forms::FormBuilder.build() do
      append_property(:switch_1, example('switch'))
      append_conditional_property(:switch_2, example('switch'), dependent_on: :switch_1, type: :const, value: true) do |f, field|
        form2 = f
        f.append_conditional_property(:switch_3, example('switch'), dependent_on: :switch_2, type: :const, value: true) do |f, field|
          form3 = f
        end
      end
    end

    
    # test current_level counter, current_form yield
    forms = [form1, form2, form3]
    forms.each_with_index do |f, index|
      i = index
      form1.each_form(start_level: index) do |current_form, current_level|
        assert_equal i, current_level
        assert_same forms[current_level], current_form
        i += 1
      end
    end
    
  end
  
  def test_each_form_2
    form1_1 = form1_2 = form2_1 = form2_2 = nil

    form = JSF::Forms::FormBuilder.build() do
      append_property(:switch_1, example('switch'))
      append_conditional_property(:switch_1_1, example('switch'), dependent_on: :switch_1, type: :const, value: true) do |f, field|
        form1_1 = f
        f.append_conditional_property(:switch_1_2, example('switch'), dependent_on: :switch_1_1, type: :const, value: true) do |f, field|
          form1_2 = f
        end
      end
      append_conditional_property(:switch_2_1, example('switch'), dependent_on: :switch_1, type: :const, value: false) do |f, field|
        form2_1 = f
        f.append_conditional_property(:switch_2_2, example('switch'), dependent_on: :switch_2_1, type: :const, value: true) do |f, field|
          form2_2 = f
        end
      end
    end

    # all forms are yielded
    forms = []
    form.each_form do |current_form, current_level|
      forms.push(current_form)
      current_form != form1_1
    end
    assert_equal 5, forms.size
    assert_empty (forms - [form, form1_1, form1_2, form2_1, form2_2])

    # test trees are halted when condition_proc returns false
    forms = []
    form.each_form(
      condition_proc: ->(condition){ !condition.dig(:then, :properties).key?('switch_1_1') }
    ) do |current_form, current_level|
      forms.push(current_form)
    end
    assert_equal 3, forms.size
    assert_empty (forms - [form, form2_1, form2_2])

  end

  # def test_max_score
  # end

  # def test_specific_max_score
  # end

  # def test_clean_document
  # end

  def test_scored?
    form = JSF::Forms::Form.new()

    assert_equal false, form.scored?
    form.append_property(:switch_1, JSF::Forms::FormBuilder.example('switch'))
    assert_equal true, form.scored?
  end

  # def test_i18n_document
  # end

  # def test_i18n_document_value
  # end

  # def test_nil_document
  # end

  # def test_compile
  # end

  # def test_migrate
  # end

end