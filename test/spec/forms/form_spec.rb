require 'json_schema_form_test_helper'

class FormTest < Minitest::Test

  #############
  #validations#
  #############

  def test_property_key_must_match_property_id
    form_example = JSF::Forms::FormBuilder.example('form')
    form = JSF::Forms::FormBuilder.build(form_example) do
      append_property :header_1, example('header').merge({:$id => '#/properties/header_1'})
    end
    assert_empty form.errors
    form[:properties][:header_1][:$id] = '#/_properties/header_1'
    refute_empty form.errors
  end

  # ToDo add more

  ############
  #transforms#
  ############

  def test_transform
    form = JSF::Forms::FormBuilder.build() do
      add_response_set(:response_set_1, example('response_set'))

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
    assert_instance_of JSF::Forms::ResponseSet, form[:definitions][:response_set_1]

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

  def test_valid_for_locale
    form_example = JSF::Forms::FormBuilder.example('form')
    form = JSF::Forms::Form.new(form_example)

    #default example is valid
    assert_equal true, form.valid_for_locale?

    #ToDo more examples
    # JSF::Forms::FormBuilder.new(form) do
    #   append_property :prop1, JSF::Forms::FormBuilder.example('select')
    # end

    # form[:properties][:prop1].set_label_for_locale('')
  end

  # def test_nil_document
  # end

  # def test_compile!
  # end

  # def test_migrate!
  # end

end