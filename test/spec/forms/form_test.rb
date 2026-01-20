# frozen_string_literal: true

require 'test_helper'

class FormTest < Minitest::Test

  ##############
  # transforms # 
  ##############

  def test_transform
    form = JSF::Forms::FormBuilder.build do
      # $defs
      add_response_set(:response_set_1, example('response_set'))
      add_shared_def(db_id: 1)
      add_def('form1', JSF::Forms::FormBuilder.example('form'))

      # properties
      append_property(:checkbox, example('checkbox'))
      append_property(:shared, example('shared'))
      append_property(:date_input, example('date_input'))
      append_property(:file_input, example('file_input'))
      append_property(:markdown, example('markdown'))
      append_property(:number_input, example('number_input'))
      append_property(:select, example('select')) do |_f|
        # conditional properties
        append_property(:checkbox2, example('checkbox'), type: :const, value: 1)
      end
      append_property(:slider, example('slider'))
      append_property(:static, example('static'))
      append_property(:text_input, example('text_input'))
      append_property(:time_input, example('time_input'))
      append_property(:signature, example('signature'))
      append_property(:video, example('video'))
      append_property(:slideshow, example('slideshow'))
    end

    # $defs
    assert_instance_of JSF::Forms::Form, form[:$defs][:form1]
    assert_instance_of JSF::Forms::ResponseSet, form[:$defs][:response_set_1]
    assert_instance_of JSF::Forms::SharedRef, form[:$defs].find { |k, _v| k.start_with?('shared') }&.last

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

  ###############
  # VALIDATIONS #
  ###############

  # errors

  def test_subschema_properties_validation
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :subschema_properties }

    form = JSF::Forms::Form.new

    assert_empty form.errors(if: error_proc)

    form.meta[:is_subschema] = true

    refute_empty form.errors(if: error_proc)

    form = JSF::Forms::FormBuilder.build(form) do
      append_property(:switch_1, example('switch'))
    end

    assert_empty form.errors(if: error_proc)
  end

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

  def test_shared_presence_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :shared_presence }
    form = JSF::Forms::FormBuilder.build do
      add_shared_pair(db_id: 1, index: :prepend)
    end

    # no errors
    assert_empty form.errors(if: error_proc)

    # missmatch id
    form[:$defs] = { other_key: form[:$defs].first.last }
    # form[:$defs].first.last.shared_def_pointer = '__key__'

    refute_empty form.errors(if: error_proc)

    # not present
    form[:properties] = {}

    refute_empty form.errors(if: error_proc)
  end

  def test_match_key_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :match_key }

    # in root schema
    form = JSF::Forms::FormBuilder.build do
      append_property :switch_1, example('switch').merge({:$id => '#/properties/switch_1'})
    end

    assert_empty form.errors(if: error_proc)
    form.dig(:properties, :switch_1)[:$id] = '#/properties/__switch_1'

    refute_empty form.errors(if: error_proc)

    # nested
    form = JSF::Forms::FormBuilder.build do
      append_property :switch_1, example('switch') do |f|
        f[:$id] = '#/properties/switch_1'

        append_property(:switch_2, example('switch'), type: :const, value: true) do |f|
          f[:$id] = '#/properties/switch_2'
        end
      end
    end

    assert_empty form.errors(if: error_proc)
    form.dig(:allOf, 0, :then, :properties, :switch_2)[:$id] = '#/properties/__switch_2'

    refute_empty form.errors(if: error_proc)
  end

  def test_response_set_presence_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :response_set_presence }

    form = JSF::Forms::FormBuilder.build do
      append_property(:select1, example('select')).tap do |field|
        field.response_set_id = :response_set_1
      end
    end

    refute_empty form.errors(if: error_proc)
    form.add_response_set(:response_set_1, JSF::Forms::FormBuilder.example('response_set'))

    assert_empty form.errors(if: error_proc)
  end

  def test_shared_in_root_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :shared_in_root }
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch1, example('switch'))
      add_shared_pair(db_id: 1, index: 0)
    end

    assert_empty form.errors(if: error_proc)

    form.append_conditional_property(:shared_2, JSF::Forms::FormBuilder.example('shared'), dependent_on: :switch1, type: :const, value: true)

    refute_empty form.errors(if: error_proc).dig(:allOf, 0, :then, :base)
  end

  def test_shared_ref_presence_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :shared_ref_presence }
    db_id = 1

    form = JSF::Forms::FormBuilder.build do
      append_property(:shared_1, example('shared'))
    end

    refute_empty form.errors(if: error_proc)

    def_obj = form.add_shared_def(db_id:)
    form.properties.first.last.shared_def_pointer = def_obj.key_name

    assert_empty form.errors(if: error_proc)
  end

  # @todo test more fields?
  def test_conditional_fields_error
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Form) && key == :conditional_fields }
    form = JSF::Forms::FormBuilder.build do
      append_property(:text_input1, example('text_input')) # cannot have conditional
      append_property(:switch1, example('switch')) do |_f|
        append_property :dependent_text_input1, example('text_input'), type: :const, value: true
      end
    end

    assert_empty form.errors(if: error_proc)
    form.append_conditional_property(:dependent_text_input2, JSF::Forms::FormBuilder.example('text_input'), dependent_on: :text_input1, type: :const, value: true)

    refute_empty form.errors(if: error_proc)
  end

  # TODO: move this to Condition spec?
  def test_conditions_format
    error_proc = ->(obj, key) { obj.is_a?(JSF::Forms::Condition) && key == :schema }
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch1, example('switch')) do |_f|
        append_property :dependent_text_input1, example('text_input'), type: :const, value: true
      end
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
    form = JSF::Forms::Form.new({}, meta: { is_subschema: true })

    assert_empty form.errors(unless: ->(_, k) { k == :subschema_properties })
  end

  # valid_for_locale?

  def test_not_valid_for_locale_when_field_is_not_valid
    form = JSF::Forms::FormBuilder.build do
      append_property :prop1, JSF::Forms::FormBuilder.example('markdown')
    end

    assert_equal true, form.valid_for_locale?
    form.get_property(:prop1).set_label_for_locale(nil)

    assert_equal false, form.valid_for_locale?
  end

  def test_not_valid_for_locale_when_conditional_field_is_not_valid
    form = JSF::Forms::FormBuilder.build do
      append_property :switch1, JSF::Forms::FormBuilder.example('switch') do |_f|
        append_property :dependent_markdown, example('markdown'), type: :const, value: true
      end
    end

    assert_equal true, form.valid_for_locale?
    form.get_merged_property(:dependent_markdown).set_label_for_locale(nil)

    assert_equal false, form.valid_for_locale?
  end

  def test_not_valid_for_locale_when_response_set_invalid
    form = JSF::Forms::FormBuilder.build do
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response'))
      end

      append_property(:select1, example('select'), {required: true}).tap do |field|
        field.response_set_id = :response_set_1
      end
    end

    assert_equal true, form.valid_for_locale?
    form.response_sets[:response_set_1][:anyOf].each { |r| r.set_translation(nil) }

    assert_equal false, form.valid_for_locale?
  end

  def test_valid_for_locale_when_invalid_unused_response_set
    form = JSF::Forms::FormBuilder.build do
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response'))
      end
      append_property :dependent_markdown, example('markdown')
    end

    assert_equal true, form.valid_for_locale?
    form.response_sets[:response_set_1][:anyOf].each { |r| r.set_translation(nil) }

    assert_equal false, form.response_sets[:response_set_1].valid_for_locale?
  end

  ###########
  # METHODS #
  ###########

  # def test_example
  # end

  # def test_shared_ref_key
  # end

  def test_shared_defs
    form = JSF::Forms::FormBuilder.build do
      add_shared_def(db_id: 1)
      add_def(:some_key, JSF::Forms::Form.new)
    end

    assert_equal 2, form.shared_defs.size
  end

  def test_add_shared_def
    form = JSF::Forms::FormBuilder.build do
      add_shared_def(db_id: 1)
    end

    assert_equal true, form['$defs'].one? { |_k, v| v.is_a?(JSF::Forms::SharedRef) }
  end

  def test_get_shared_def
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_shared_def(db_id:)
    end

    assert_instance_of JSF::Forms::SharedRef, form.get_shared_def(db_id:)
  end

  def test_remove_shared_def
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_shared_def(db_id:)
    end

    form.remove_shared_def(db_id:)

    assert_empty form['$defs']
  end

  def test_add_shared_pair
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_shared_pair(db_id:, index: :append)
    end

    shared_ref = form.get_shared_def(db_id:)

    assert_instance_of JSF::Forms::SharedRef, shared_ref
    assert_instance_of JSF::Forms::Field::Shared, shared_ref&.shared
  end

  def test_remove_shared_pair
    db_id = 1
    form = JSF::Forms::FormBuilder.build do
      add_shared_pair(db_id:, index: :append)
      remove_shared_pair(db_id:)
    end

    assert_empty form['$defs']
    assert_empty form['properties']
  end

  # def test_response_sets
  # end

  # def test_add_response_set
  # end

  def test_properties
    form = JSF::Forms::FormBuilder.build

    assert_same form.properties, form[:properties]
  end

  def test_merged_properties
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch')) do |_f|
        append_property(:switch_2, example('switch'), type: :const, value: true) do
          append_property(:switch_3, example('switch'), type: :const, value: true) do
            append_property(:switch_4, example('switch'), type: :const, value: true)
          end
        end
      end
    end

    assert_equal %w[switch_1 switch_2 switch_3 switch_4], form.merged_properties.keys
    assert_equal %w[switch_2 switch_3 switch_4], form.merged_properties(start_level: 1).keys
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
      append_property(:switch_1, example('switch')) do
        append_property(:switch_2, example('switch'), type: :const, value: true)
      end
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

    assert_equal %w[switch_3 switch_1 switch_2], form.sorted_properties.map(&:key_name)
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

  def test_get_conditions
    form = JSF::Forms::FormBuilder.build do
      append_property(:prop1, example('select'))
      add_condition('prop1', :const, 'const')
      add_condition('prop1', :not_const, 'not_const')
      add_condition('prop1', :enum, ['enum'])
      add_condition('prop1', :not_enum, ['not_enum'])
    end

    # found
    assert_equal 'const', form.get_conditions(:prop1, :const, 'const').first.dig(:if, :properties, :prop1, :const)
    assert_equal 'not_const', form.get_conditions(:prop1, :not_const, 'not_const').first.dig(:if, :properties, :prop1, :not, :const)
    assert_equal ['enum'], form.get_conditions(:prop1, :enum, 'enum').first.dig(:if, :properties, :prop1, :enum)
    assert_equal ['not_enum'], form.get_conditions(:prop1, :not_enum, 'not_enum').first.dig(:if, :properties, :prop1, :not, :enum)

    # not found
    assert_nil form.get_conditions(:prop1, :const, 'other_value').first

    # invalid key
    assert_raises(ArgumentError) { form.get_conditions(:prop1, :wrong_key, 'other_value') }
  end

  def test_add_condition
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch'))
    end

    # add new condition
    condition = form.add_condition('switch_1', :const, true)

    assert_instance_of JSF::Forms::Condition, condition

    # invalid key
    assert_raises(ArgumentError) { form.add_condition(:prop1, :wrong_key, true) }

    # non-existing prop
    assert_raises(ArgumentError) { form.add_condition(:other_prop, :const, true) }
  end

  def test_insert_conditional_property_at_index
    # raises error when field does not exist
    assert_raises (ArgumentError) do
      JSF::Forms::FormBuilder.build do
        insert_conditional_property_at_index(0, :switch_2, example('switch'), dependent_on: :switch_1, type: :const, value: true)
      end
    end

    # correct sorting
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch')) do
        insert_property_at_index(0, :switch_2, example('switch'), type: :const, value: true)
        insert_property_at_index(0, :switch_3, example('switch'), type: :const, value: true) do
          insert_property_at_index(1, :switch_4, example('switch'), type: :const, value: true)
        end
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

  # def test_is_shared_def?
  # end

  # def test_validation_schema
  # end

  def test_each_form
    # create vars to store forms in
    form2 = form3 = form4 = form5 = form6 = nil

    # build the form
    form1 = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch')) do
        append_property(:switch_2, example('switch'), type: :const, value: true) do |_f, subform|
          form2 = subform
          append_property(:switch_3, example('switch'), type: :const, value: true) do |_f, subform|
            form3 = subform
          end
        end

        append_property(:section_2, example('section'), type: :const, value: false) do |f, subform|
          form4 = subform
          form5 = f.form
          f.form.instance_eval do
            append_property(:switch_4, example('switch'))
          end
        end
      end

      append_property(:section_1, example('section')) do |f|
        form6 = f.form
        f.form.instance_eval do
          append_property(:switch_6, example('switch'))
        end
      end
    end

    # test all forms are yielded, only once
    forms = []
    form1.each_form do |current_form|
      forms.push(current_form)
    end

    assert_equal 6, forms.size
    assert_empty (forms - [form1, form2, form3, form4, form5, form6])

    # test yields
    # form1.each_form do |current_form, condition, current_level|
    #   assert_instance_of JSF::Forms::Form, current_form
    #   assert_equal true, (condition.nil? || condition.is_a?(JSF::Forms::Condition))
    #   assert_instance_of Integer, current_level
    # end

    # ignore_defs
    forms = []
    form1.each_form(ignore_defs: true) do |current_form|
      forms.push(current_form)
    end

    assert_equal 6, forms.size
    assert_empty (forms - [form1, form2, form3, form4, form5, form6])

    # ignore_all_of
    forms = []
    form1.each_form(ignore_all_of: true) do |current_form|
      forms.push(current_form)
    end

    assert_equal 2, forms.size
    assert_empty (forms - [form1, form6])

    # ignore_sections
    forms = []
    form1.each_form(ignore_sections: true) do |current_form|
      forms.push(current_form)
    end

    assert_equal 4, forms.size
    assert_empty (forms - [form1, form2, form3, form4])

    # test trees are halted when yielded skip_branch is thrown
    forms = []
    form1.each_form do |current_form|
      throw(:skip_branch, true) if current_form.dig(:properties, :switch_2)
      forms.push(current_form)
    end

    assert_equal 4, forms.size
    assert_empty (forms - [form1, form4, form5, form6])

    # test hidden is ignored when skip_tree_when_hidden is false
    hide_props = %w[switch_1 section_1]
    hide_props.each { |key| form1.get_property(key).hidden = true }
    forms = []
    form1.each_form(skip_tree_when_hidden: false) do |current_form|
      forms.push(current_form)
    end

    assert_equal 6, forms.size
    assert_empty (forms - [form1, form2, form3, form4, form5, form6])
    hide_props.each { |key| form1.get_property(key).hidden = false } # restore

    # test hidden property does not yield dependent forms when skip_tree_when_hidden is true
    hide_props = ['switch_1']
    hide_props.each { |key| form1.get_property(key).hidden = true }
    forms = []
    form1.each_form(skip_tree_when_hidden: true) do |current_form|
      forms.push(current_form)
    end

    assert_equal 2, forms.size
    assert_empty (forms - [form1, form6])
    hide_props.each { |key| form1.get_property(key).hidden = false } # restore

    # test hidden section does not yield dependent form when skip_tree_when_hidden is true
    hide_props = ['section_1']
    hide_props.each { |key| form1.get_property(key).hidden = true }
    forms = []
    form1.each_form(skip_tree_when_hidden: true) do |current_form|
      forms.push(current_form)
    end

    assert_equal 5, forms.size
    assert_empty (forms - [form1, form2, form3, form4, form5])
    hide_props.each { |key| form1.get_property(key).hidden = false } # restore

    # test hideOnCreate is ignored when skip_tree_when_hidden is false
    hide_props = %w[switch_1 section_1]
    hide_props.each { |key| form1.get_property(key).hideOnCreate = true }
    forms = []
    form1.each_form(skip_tree_when_hidden: false) do |current_form|
      forms.push(current_form)
    end

    assert_equal 6, forms.size
    assert_empty (forms - [form1, form2, form3, form4, form5, form6])
    hide_props.each { |key| form1.get_property(key).hidden = false } # restore

    # test hideOnCreate is ignored when skip_tree_when_hidden is true and is_create is false
    hide_props = %w[switch_1 section_1]
    hide_props.each { |key| form1.get_property(key).hideOnCreate = true }
    forms = []
    form1.each_form(skip_tree_when_hidden: true, is_create: false) do |current_form|
      forms.push(current_form)
    end

    assert_equal 6, forms.size
    assert_empty (forms - [form1, form2, form3, form4, form5, form6])
    hide_props.each { |key| form1.get_property(key).hideOnCreate = false } # restore

    # test hideOnCreate property does not yield dependent forms when skip_tree_when_hidden is true and is_create is true
    hide_props = ['switch_1']
    hide_props.each { |key| form1.get_property(key).hideOnCreate = true }
    forms = []
    form1.each_form(skip_tree_when_hidden: true, is_create: true) do |current_form|
      forms.push(current_form)
    end

    assert_equal 2, forms.size
    assert_empty (forms - [form1, form6])
    hide_props.each { |key| form1.get_property(key).hideOnCreate = false } # restore
  end

  def test_each_form_with_document
    # build the form
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch')) do
        append_property(:switch_2, example('switch'), type: :const, value: true) do
          append_property(:switch_3, example('switch'), type: :const, value: true)
        end

        append_property(:section_1, example('section'), type: :const, value: false) do |f|
          f.form.instance_eval do
            append_property(:switch_4, example('switch'))
          end
        end
      end
    end

    # when the document is empty
    count = 0
    form.each_form_with_document({}) do |_form, _condition, _current_level, current_doc, current_empty_doc, document_path|
      count += 1

      assert_empty current_doc
      assert_empty current_empty_doc
      assert_empty document_path
    end
    assert_equal 4, count

    # when the document has values
    count = 0
    document = {'switch_1' => true, 'switch_2' => true, 'section_1' => [{'switch_4' => true}, {'switch_4' => false}]}
    form.each_form_with_document(document) do |form, _condition, _current_level, current_doc, current_empty_doc, document_path|
      count += 1

      if form.properties.keys.intersect?(%w[switch_1 switch_2 switch_3 section_1])
        assert_empty document_path
        assert_equal '{"switch_1" => true, "switch_2" => true, "section_1" => [{"switch_4" => true}, {"switch_4" => false}]}', current_doc.to_s
      else
        refute_empty document_path
        case document_path.to_s
        when '["section_1", 0]'

          assert_equal '{"switch_4" => true}', current_doc.to_s
        when '["section_1", 1]'

          assert_equal '{"switch_4" => false}', current_doc.to_s
        else
          raise StandardError.new
        end
      end

      assert_empty current_empty_doc
    end
    assert_equal 6, count
  end

  def test_each_sorted_property
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch')) do
        append_property(:number_input_1, example('number_input'), type: :const, value: true) do
          append_property(:markdown_1, example('markdown'), type: :const, value: 10)
          append_property(:markdown_2, example('markdown'), type: :enum, value: [10])
          append_property(:markdown_3, example('markdown'), type: :not_const, value: 10)
        end

        append_property(:number_input_2, example('number_input'), type: :const, value: true)

        append_property(:section_2, example('section'), type: :const, value: true) do |f|
          f.form.instance_eval do
            append_property(:switch_4, example('switch'))
            append_property(:switch_5, example('switch'))
          end
        end
      end

      append_property(:section_1, example('section')) do |f|
        f.form.instance_eval do
          append_property(:switch_6, example('switch'))
        end
      end
    end

    array = []
    form.each_sorted_property do |property|
      array.push(property.key_name)
    end

    assert_equal array, %w[switch_1 number_input_1 markdown_1 markdown_2 markdown_3 number_input_2 section_2 switch_4 switch_5 section_1 switch_6]
  end

  def test_each_sorted_form_with_document
    form = JSF::Forms::FormBuilder.build do
      append_property(:switch_1, example('switch')) do
        append_property(:number_input_1, example('number_input'), type: :const, value: true) do
          append_property(:markdown_1, example('markdown'), type: :const, value: 10)
          append_property(:markdown_2, example('markdown'), type: :enum, value: [10])
          append_property(:markdown_3, example('markdown'), type: :not_const, value: 10)
        end

        append_property(:number_input_2, example('number_input'), type: :const, value: true)

        append_property(:section_2, example('section'), type: :const, value: true) do |f|
          f.form.instance_eval do
            append_property(:switch_4, example('switch'))
            append_property(:switch_5, example('switch'))
          end
        end
      end

      append_property(:section_1, example('section')) do |f|
        f.form.instance_eval do
          append_property(:switch_6, example('switch'))
        end
      end
    end

    document = {'switch_1' => true, 'number_input_1' => 10, 'section_2' => [{}, {}], 'section_1' => []}
    array = []
    form.each_sorted_form_with_document(document) do |property|
      array.push(property.key_name)
    end

    assert_equal array, %w[switch_1 number_input_1 markdown_1 markdown_2 number_input_2 section_2 switch_4 switch_5 section_2 switch_4 switch_5 section_1]
  end

  def test_cleaned_document
    form = JSF::Forms::FormBuilder.build do
      # add response sets
      add_response_set(:'bc0214f2-807c-4806-8edf-17d118467825', example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'option_1'
        end
      end

      # field with response set
      append_property(:select, example('select')) do |f|
        f.response_set_id = 'bc0214f2-807c-4806-8edf-17d118467825'
      end

      # nested conditional
      append_property(:switch_1, example('switch')) do
        append_property(:switch_2, example('switch'), type: :const, value: true) do
          append_property(:switch_3, example('switch'), type: :const, value: true)
        end
      end

      # section
      append_property(:section_1, example('section')) do |f|
        f.form.instance_eval do
          append_property(:number_input_section, example('number_input')) do
            append_property(:sub_section_1, example('section'), type: :const, value: 1) do |f|
              f.form.instance_eval do
                append_property(:multiselect_section, example('select')) do |f|
                  f.response_set_id = 'bc0214f2-807c-4806-8edf-17d118467825'
                end
              end
            end
          end
        end
      end

      # hidden on create
      append_property(:hide_on_create, example('text_input')) do |f|
        SuperHash::Utils.bury(f, :displayProperties, :hideOnCreate, true)
      end

      # hidden
      append_property(:hidden, example('text_input')) do |f|
        SuperHash::Utils.bury(f, :displayProperties, :hidden, true)
      end
    end

    # allows meta
    document = {'meta' => {'some_key' => 1}}
    expected = '{"section_1" => [], "meta" => {"some_key" => 1}}'

    assert_equal expected, form.cleaned_document(document).to_s

    # removes hidden
    document = {'hidden' => 'hey' }
    expected = '{"section_1" => []}'

    assert_equal expected, form.cleaned_document(document).to_s

    # allows hide_on_create on create when not is_create
    document = {'hide_on_create' => 'hey' }
    expected = '{"hide_on_create" => "hey", "section_1" => []}'

    assert_equal expected, form.cleaned_document(document).to_s

    # removes hide_on_create on create when is_create
    document = {'hide_on_create' => 'hey' }
    expected = '{"section_1" => []}'

    assert_equal expected, form.cleaned_document(document, is_create: true).to_s

    # empty document
    document = {}
    expected = '{"section_1" => []}'

    assert_equal expected, form.cleaned_document(document).to_s

    # known property
    document = {'switch_1' => true }
    expected = '{"switch_1" => true, "section_1" => []}'

    assert_equal expected, form.cleaned_document(document).to_s

    # unknown property
    document = {'other_prop' => true }
    expected = '{"section_1" => []}'

    assert_equal expected, form.cleaned_document(document).to_s

    # known dynamic property
    document = {'switch_1' => true, 'switch_2' => true }
    expected = '{"switch_1" => true, "section_1" => [], "switch_2" => true}'

    assert_equal expected, form.cleaned_document(document).to_s

    # hidden dynamic property
    document = {'switch_1' => false, 'switch_2' => true }
    expected = '{"switch_1" => false, "section_1" => []}'

    assert_equal expected, form.cleaned_document(document).to_s

    # deep hidden dynamic property
    document = {'switch_1' => true, 'switch_2' => false, 'switch_3' => true }
    expected = '{"switch_1" => true, "section_1" => [], "switch_2" => false}'

    assert_equal expected, form.cleaned_document(document).to_s

    # unknown property in section
    document = {'section_1' => [{ 'some_prop' => 3 }] }
    expected = '{"section_1" => [{}]}'

    assert_equal expected, form.cleaned_document(document).to_s

    # known property in section
    document = {'section_1' => [{ 'number_input_section' => 2 }] }
    expected = '{"section_1" => [{"number_input_section" => 2}]}'

    assert_equal expected, form.cleaned_document(document).to_s

    # dynamic property in section
    document = {'section_1' => [{ 'number_input_section' => 1 }] }
    expected = '{"section_1" => [{"number_input_section" => 1, "sub_section_1" => []}]}'

    assert_equal expected, form.cleaned_document(document).to_s
  end

  # non scorable fields
  def test_set_specific_max_scores!
    ### NON SCORABLE FIELDS ###

    empty_form = JSF::Forms::FormBuilder.build

    root_non_scorable_form = JSF::Forms::FormBuilder.build do
      append_property(:markdown_1, example('markdown'))
    end

    # general cases where nil
    bools = [true, false]
    docs = [{}, {'some_key' => 1}]
    [empty_form, root_non_scorable_form].each do |form|
      bools.each do |is_create|
        docs.each do |doc|
          assert_nil form.set_specific_max_scores!(doc, is_create:)
          if doc.key? 'some_key'
            assert_equal '{"some_key" => 1, "meta" => {"specific_max_score_hash" => {}, "specific_max_score_total" => nil}}', doc.to_s
          else
            assert_equal '{"meta" => {"specific_max_score_hash" => {}, "specific_max_score_total" => nil}}', doc.to_s
          end
        end
      end
    end

    form = JSF::Forms::FormBuilder.build do
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'score_0'
          r[:score] = 0
          r.set_translation('score 0', 'es')
        end
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'score_1'
          r[:score] = 1
          r.set_translation('score 1', 'es')
        end
      end

      append_property(:select_1, example('select')) do |f|
        f.response_set_id = :response_set_1
        append_property(:markdown_1_1, example('markdown'), type: :enum, value: ['score_0'])
      end
    end

    [
      {
        doc: {'select_1' => nil},
        hash: {'select_1' => 1},
        total: 1
      },
      {
        doc: {'select_1' => 'score_1'},
        hash: {'select_1' => 1},
        total: 1
      },
      {
        doc: {'select_1' => 'score_0'},
        hash: {'select_1' => 1},
        total: 1
      }
    ].each do |obj|
      assert_equal obj[:total], form.set_specific_max_scores!(obj[:doc])
      assert_equal obj[:doc]['meta']['specific_max_score_hash'], obj[:hash]
    end

    ### SCORABLE FIELDS ###

    form = JSF::Forms::FormBuilder.build do
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'nil_score'
          r[:score] = nil
        end
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'score_3'
          r[:score] = 3
        end
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'score_6'
          r[:score] = 6
        end
      end

      add_response_set(:response_set_2, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'nil_score'
          r[:score] = nil
        end
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'score_1'
          r[:score] = 1
        end
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'score_2'
          r[:score] = 2
        end
      end

      append_property(:markdown_1, example('markdown'))
      append_property(:switch_1, example('switch'))

      append_property(:select_1, example('select')) do |f|
        f.response_set_id = :response_set_1

        append_property(:select_1_1, example('select'), type: :enum, value: %w[nil_score score_3]) do |f|
          f.response_set_id = :response_set_2

          append_property(:select_1_1_1, example('select'), type: :const, value: 'nil_score') do |f|
            f.response_set_id = :response_set_1
          end

          append_property(:checkbox_1_1_2, example('checkbox'), type: :enum, value: %w[nil_score score_1]) do |f|
            f.response_set_id = :response_set_2
          end
        end
      end

      append_property(:section_1, example('section')) do |f|
        f.form.instance_eval do
          append_property(:slider_sec_1, example('slider'))
          append_property(:number_input_sec_2, example('number_input')) do
            append_property(:select_sec_1_1, example('select'), type: :const, value: 1) do |f|
              f.response_set_id = :response_set_2

              append_property(:switch_1_1_1, example('switch'), type: :const, value: 'score_2')
              append_property(:section_1_1_1, example('section'), type: :const, value: 'score_1') do |f, _|
                f.form.instance_eval do
                  append_property(:switch_1_1_1_1, example('switch'))
                end
              end
            end
          end
        end
      end
    end

    values = [
      {
        doc: {},
        hash: {'switch_1' => 1, 'select_1' => 6, 'section_1' => []},
        total: 7.0
      },
      {
        doc: {'section_1' => [{}]},
        hash: {'switch_1' => 1, 'select_1' => 6, 'section_1' => [{'slider_sec_1' => 10}]},
        total: 17.0
      },
      {
        doc: {'section_1' => [{}, {}]},
        hash: {'switch_1' => 1, 'select_1' => 6, 'section_1' => [{'slider_sec_1' => 10}, {'slider_sec_1' => 10}]},
        total: 27.0
      },
      {
        doc: {'switch_1' => true, 'section_1' => [{}]},
        hash: {'switch_1' => 1, 'select_1' => 6, 'section_1' => [{'slider_sec_1' => 10}]},
        total: 17.0
      },
      {
        doc: {'switch_1' => false, 'slider_sec_1' => 8, 'section_1' => [{}]},
        hash: {'switch_1' => 1, 'select_1' => 6, 'section_1' => [{'slider_sec_1' => 10}]},
        total: 17.0
      },
      {
        doc: {'select_1' => nil, 'section_1' => [{}]},
        hash: {'switch_1' => 1, 'select_1' => 6, 'section_1' => [{'slider_sec_1' => 10}]},
        total: 17.0
      },
      {
        doc: {'select_1' => 'nil_score', 'section_1' => [{}]},
        hash: {'switch_1' => 1, 'select_1' => nil, 'section_1' => [{'slider_sec_1' => 10}], 'select_1_1' => 2},
        total: 13.0
      },
      {
        doc: {'select_1' => 'score_3', 'section_1' => [{}]},
        hash: {'switch_1' => 1, 'select_1' => 3, 'section_1' => [{'slider_sec_1' => 10}], 'select_1_1' => 2},
        total: 16.0
      },
      {
        doc: {'select_1' => 'score_6', 'section_1' => [{}] },
        hash: {'switch_1' => 1, 'select_1' => 6, 'section_1' => [{'slider_sec_1' => 10}]},
        total: 17.0
      },
      {
        doc: {'select_1' => 'nil_score', 'select_1_1' => 'nil_score', 'section_1' => [{}] },
        hash: {'switch_1' => 1, 'select_1' => nil, 'section_1' => [{'slider_sec_1' => 10}], 'select_1_1' => nil, 'select_1_1_1' => 6, 'checkbox_1_1_2' => 3},
        total: 20.0
      },
      {
        doc: {'select_1' => 'nil_score', 'select_1_1' => 'nil_score', 'section_1' => [{'number_input_sec_2' => 2}] },
        hash: {'switch_1' => 1, 'select_1' => nil, 'section_1' => [{'slider_sec_1' => 10}], 'select_1_1' => nil, 'select_1_1_1' => 6, 'checkbox_1_1_2' => 3},
        total: 20.0
      },
      {
        doc: {'select_1' => 'nil_score', 'select_1_1' => 'nil_score', 'section_1' => [{'number_input_sec_2' => 1}] },
        hash: {'switch_1' => 1, 'select_1' => nil, 'section_1' => [{'slider_sec_1' => 10, 'select_sec_1_1' => 2}], 'select_1_1' => nil, 'select_1_1_1' => 6, 'checkbox_1_1_2' => 3},
        total: 22.0
      },
      {
        doc: {'select_1' => 'nil_score', 'select_1_1' => 'nil_score', 'section_1' => [{'number_input_sec_2' => 2}, {'number_input_sec_2' => 1}] },
        hash: {'switch_1' => 1, 'select_1' => nil, 'section_1' => [{'slider_sec_1' => 10}, {'slider_sec_1' => 10, 'select_sec_1_1' => 2}], 'select_1_1' => nil, 'select_1_1_1' => 6, 'checkbox_1_1_2' => 3},
        total: 32.0
      },
      {
        doc: {'select_1' => 'nil_score', 'select_1_1' => 'nil_score', 'section_1' => [{'number_input_sec_2' => 1}, {'number_input_sec_2' => 1}] },
        hash: {'switch_1' => 1, 'select_1' => nil, 'section_1' => [{'slider_sec_1' => 10, 'select_sec_1_1' => 2}, {'slider_sec_1' => 10, 'select_sec_1_1' => 2}], 'select_1_1' => nil, 'select_1_1_1' => 6, 'checkbox_1_1_2' => 3},
        total: 34.0
      },
      {
        doc: {'select_1' => 'nil_score', 'select_1_1' => 'nil_score', 'section_1' => [{'number_input_sec_2' => 1}, {'number_input_sec_2' => 1, 'select_sec_1_1' => 'score_1'}] },
        hash: {'switch_1' => 1, 'select_1' => nil, 'section_1' => [{'slider_sec_1' => 10, 'select_sec_1_1' => 2}, {'slider_sec_1' => 10, 'select_sec_1_1' => 2, 'section_1_1_1' => []}], 'select_1_1' => nil, 'select_1_1_1' => 6, 'checkbox_1_1_2' => 3},
        total: 34.0
      },
      {
        doc: {'select_1' => 'nil_score', 'select_1_1' => 'nil_score', 'section_1' => [{'number_input_sec_2' => 1}, {'number_input_sec_2' => 1, 'select_sec_1_1' => 'score_2'}] },
        hash: {'switch_1' => 1, 'select_1' => nil, 'section_1' => [{'slider_sec_1' => 10, 'select_sec_1_1' => 2}, {'slider_sec_1' => 10, 'select_sec_1_1' => 2, 'switch_1_1_1' => 1}], 'select_1_1' => nil, 'select_1_1_1' => 6, 'checkbox_1_1_2' => 3},
        total: 35.0
      },
      {
        doc: {'select_1' => 'nil_score', 'select_1_1' => 'nil_score', 'section_1' => [{'number_input_sec_2' => 1}, {'number_input_sec_2' => 1, 'select_sec_1_1' => 'score_1', 'section_1_1_1' => [{}, {}]}] },
        hash: {'switch_1' => 1, 'select_1' => nil, 'section_1' => [{'slider_sec_1' => 10, 'select_sec_1_1' => 2}, {'slider_sec_1' => 10, 'select_sec_1_1' => 1, 'section_1_1_1' => [{'switch_1_1_1_1' => 1}, {'switch_1_1_1_1' => 1}]}], 'select_1_1' => nil, 'select_1_1_1' => 6, 'checkbox_1_1_2' => 3},
        total: 35.0
      }
    ]

    values.each do |obj|
      assert_equal obj[:total], form.set_specific_max_scores!(obj[:doc])
      assert_equal obj[:doc]['meta']['specific_max_score_hash'], obj[:hash]
    end
  end

  # def test_set_scores!
  # end

  # def test_set_failures!
  # end

  # def test_max_score
  # end

  def test_scored?
    # no fields
    form = JSF::Forms::Form.new

    assert_equal false, form.scored?

    # not scored field
    form.append_property(:markdown_1, JSF::Forms::FormBuilder.example('markdown'))

    assert_equal false, form.scored?

    # scored field
    form.append_property(:switch_1, JSF::Forms::FormBuilder.example('switch'))

    assert_equal true, form.scored?

    # non root
    complex_non_scorable_form = JSF::Forms::FormBuilder.build do
      append_property(:number_input_1, example('number_input')) do |_f|
        find_or_add_condition(:const, 1) do
          append_property(:markdown_1_1, example('markdown'), type: :const, value: 1)
          append_property(:section, example('section')) do |f|
            f.form.instance_eval do
              append_property(:switch, example('switch')) # scored
            end
          end
        end
      end
    end

    assert_equal true, complex_non_scorable_form.scored?
  end

  def test_i18n_document
    form = JSF::Forms::FormBuilder.build do
      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'value_1'
          r.set_translation('respuesta 1')
        end
        response_set.add_response(example('response', :scoring_and_failing)).tap do |r|
          r[:const] = 'value_2'
          r.set_translation('respuesta 2')
        end
      end

      # non-translatable
      append_property(:number_input, example('number_input'))

      # translatable
      append_property(:checkbox, example('checkbox')) do |f|
        f.response_set_id = :response_set_1
      end
      append_property(:select, example('select')) do |f|
        f.response_set_id = :response_set_1
      end
      append_property(:slider, example('slider'))
      append_property(:switch, example('switch')) do |_f|
        # conditional field
        append_property(:switch_1, example('switch'), type: :const, value: true)
      end

      # section
      append_property(:section, example('section')) do |f, _|
        f.form.instance_eval do
          append_property(:switch_2, example('switch'))
        end
      end
    end

    # ignores non existing fields
    i18n_doc = form.i18n_document({'some_prop' => 'hello'})

    assert_equal 'hello', i18n_doc['some_prop']

    # does not mutate non-translatable fields
    i18n_doc = form.i18n_document({'number_input' => 1})

    assert_equal 1, i18n_doc['number_input']

    # translates checkbox
    i18n_doc = form.i18n_document({'checkbox' => %w[value_1 other_value]})

    assert_equal ['respuesta 1', 'Missing Translation'], i18n_doc['checkbox']

    # translates select
    i18n_doc = form.i18n_document({'select' => 'value_1'})

    assert_equal 'respuesta 1', i18n_doc['select']
    i18n_doc = form.i18n_document({'select' => 'other_value'})

    assert_equal 'Missing Translation', i18n_doc['select']

    # translates slider
    i18n_doc = form.i18n_document({'slider' => 5})

    assert_equal '5', i18n_doc['slider']
    i18n_doc = form.i18n_document({'slider' => 500})

    assert_equal 'Missing Translation', i18n_doc['slider']

    # translates switch
    i18n_doc = form.i18n_document({'switch' => true})

    assert_equal 'Some positive text', i18n_doc['switch']
    i18n_doc = form.i18n_document({'switch' => 'other_value'})

    assert_equal 'Missing Translation', i18n_doc['switch']

    # translates logic field
    i18n_doc = form.i18n_document({'switch_1' => true})

    assert_equal 'Some positive text', i18n_doc['switch_1']
    i18n_doc = form.i18n_document({'switch_1' => 'other_value'})

    assert_equal 'Missing Translation', i18n_doc['switch_1']

    # translates field in section
    i18n_doc = form.i18n_document({'section' => [{'switch_2' => true}]})

    assert_equal 'Some positive text', i18n_doc.dig('section', 0, 'switch_2')
    i18n_doc = form.i18n_document({'section' => [{'switch_2' => 'other_value'}]})

    assert_equal 'Missing Translation', i18n_doc.dig('section', 0, 'switch_2')
  end

  # TODO: move to base_hash_test.rb?
  def test_dup_maintains_instance_variables
    field = nil
    JSF::Forms::FormBuilder.build do
      field = append_property(:number_input, example('number_input'))
    end

    assert_equal field.meta, field.dup.meta
  end

  def test_dup_does_not_re_add_default_keys
    form = JSF::Forms::Form.new

    refute_nil form['type']

    form.delete('type')

    assert_nil form.dup['type']
  end

  # def test_dup_with_new_references
  #   property_id_proc = ->(id){ id + '__1__' },
  #   response_set_id_proc = ->(id){ id + '__2__' }

  #   # nothing changes for empty schema
  #   original = JSF::Forms::FormBuilder.build
  #   dup = original.dup_with_new_references
  #   assert_equal original.to_s, dup.to_s

  #   # property changes
  #   original = JSF::Forms::FormBuilder.build do
  #     append_property(:number_input, example('number_input'))
  #   end
  #   dup = original.dup_with_new_references(property_id_proc: property_id_proc, response_set_id_proc: response_set_id_proc)
  #   # assert_equal
  # end

  # def test_sample_document
  # end

  # def test_empty_document_with_all_props
  # end

  # def test_compile
  # end

  # def test_migrate
  # end

  # def test_handle_document_changes
  # end

end