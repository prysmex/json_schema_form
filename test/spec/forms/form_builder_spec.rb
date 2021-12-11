require 'test_helper'

class FormbuilderTest < Minitest::Test

  # fixtures

  # tests .errors and .valid_for_locale?
  def test_fixtures
    klasses = {
      JSF::Forms::ComponentRef => [
        {errors_args: {unless: ->(i, key){key = :ref_presence} }}
      ],
      JSF::Forms::Form => [],
      JSF::Forms::ResponseSet => [],
      JSF::Forms::Response => [
        {trait: :default, errors_args: {is_inspection: false}},
        {trait: :is_inspection, errors_args: {is_inspection: true}}
      ],
      JSF::Forms::Section => [],
      JSF::Forms::Field::Checkbox => [
        {errors_args: {unless: ->(i, key){key = :ref_presence} }}
      ],
      JSF::Forms::Field::Component => [
        {errors_args: {unless: ->(i, key){key = :ref_presence} }}
      ],
      JSF::Forms::Field::DateInput => [],
      JSF::Forms::Field::FileInput => [],
      JSF::Forms::Field::Header => [],
      JSF::Forms::Field::Info => [],
      JSF::Forms::Field::NumberInput => [],
      JSF::Forms::Field::Select => [
        {errors_args: {unless: ->(i, key){key = :ref_presence} }}
      ],
      JSF::Forms::Field::Slider => [],
      JSF::Forms::Field::Static => [],
      JSF::Forms::Field::Switch => [],
      JSF::Forms::Field::TextInput => []
    }
    
    klasses.each do |klass, traits_array|
      skip_valid_for_locale = [JSF::Forms::ComponentRef, JSF::Forms::Section].include?(klass)

      if traits_array.empty?
        hash = JSF::Forms::FormBuilder.example_for(klass)
        instance = klass.new(hash)
        assert_equal true, instance.valid_for_locale? unless skip_valid_for_locale
        assert_empty instance.errors
      else
        traits_array.each do |obj|
          hash = JSF::Forms::FormBuilder.example_for(klass, obj[:trait])
          instance = klass.new(hash)
          assert_equal true, instance.valid_for_locale? unless skip_valid_for_locale
          assert_empty instance.errors(**obj[:errors_args])
        end
      end
    end

  end

  # builder

  def test_builder_example
    JSF::Forms::FormBuilder.build() do

      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response', :default)).tap do |r|
          r[:const] = 'option1'
          r[:score] = 0
        end
        response_set.add_response(example('response', :default)).tap do |r|
          r[:const] = 'option2'
          r[:score] = 2
        end
        response_set.add_response(example('response', :default)).tap do |r|
          r[:const] = 'option3'
          r[:score] = 5
        end
      end
    
      append_property(:select1, example('select'), {required: true}) do |f, key|
        f.response_set_id = :response_set_1

        #por separado
        append_conditional_property :depedendent_select1, example('select'), dependent_on: key, type: :const, value: 'option1'
        append_conditional_property :depedendent_select2, example('select'), dependent_on: key, type: :enum, value: ['option1']

        #nested
        append_conditional_property(:depedendent_select3, example('select'), dependent_on: key, type: :const, value: 'option2') do |f, key, subform|
          f.response_set_id = :response_set_1
          f.hidden = true
          subform.prepend_property(:depedendent_select4, example('select'), {required: true}) do |f|
            f.response_set_id = :response_set_1
            f.hidden = true
          end
        end
      end
    
    
    
    end
  end

end