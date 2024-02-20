require 'test_helper'

class FormbuilderTest < Minitest::Test

  # fixtures

  # tests .errors and .valid_for_locale?
  def test_fixtures
    klasses = {
      JSF::Forms::SharedRef => [
        {errors_args: {unless: ->(i, key){key == :ref_presence} }}
      ],
      JSF::Forms::Form => [],
      JSF::Forms::ResponseSet => [],
      JSF::Forms::Response => [
        {trait: nil, errors_args: {}},
        {trait: :scoring, errors_args: {optional_if: ->(_,k) { k == :scoring }}},
        {trait: :failing, errors_args: {optional_if: ->(_,k) { k == :failing }}},
        {trait: :scoring_and_failing , errors_args: {optional_if: ->(_,k) { %i[scoring failing].include?(k) }}},
      ],
      JSF::Forms::Section => [],

      # fields
      JSF::Forms::Field::Checkbox => [
        {errors_args: {unless: ->(i, key){key == :ref_presence} }}
      ],
      JSF::Forms::Field::Shared => [
        {errors_args: {unless: ->(i, key){key == :ref_presence} }}
      ],
      JSF::Forms::Field::DateInput => [],
      JSF::Forms::Field::FileInput => [],
      JSF::Forms::Field::GeoPoints => [],
      JSF::Forms::Field::Markdown => [],
      JSF::Forms::Field::NumberInput => [],
      JSF::Forms::Field::Select => [
        {errors_args: {unless: ->(i, key){key == :ref_presence} }}
      ],
      JSF::Forms::Field::Signature => [],
      JSF::Forms::Field::Slider => [],
      JSF::Forms::Field::Static => [],
      JSF::Forms::Field::Switch => [],
      JSF::Forms::Field::TextInput => [],
      JSF::Forms::Field::TimeInput => [],
      JSF::Forms::Field::Video => []
    }
    
    klasses.each do |klass, traits_array|
      skip_valid_for_locale = [JSF::Forms::SharedRef, JSF::Forms::Section].include?(klass)

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
        response_set.add_response(example('response')).tap do |r|
          r[:const] = 'option1'
          r[:score] = 0
        end
        response_set.add_response(example('response')).tap do |r|
          r[:const] = 'option2'
          r[:score] = 2
        end
        response_set.add_response(example('response')).tap do |r|
          r[:const] = 'option3'
          r[:score] = 5
        end
      end
    
      append_property(:select1, example('select'), required: true) do |f|
        f.response_set_id = :response_set_1
    
        #por separado
        append_property :depedendent_select1, example('select'), type: :const, value: 'option1'
        append_property :depedendent_select2, example('select'), type: :enum, value: ['option1']
    
        find_or_add_condition(:const, 'option2') do
          append_property(:depedendent_select3, example('select')) do |f|
            f.response_set_id = :response_set_1
            f.hidden = true
          end
          prepend_property(:depedendent_select4, example('select'), required: true) do |f|
            f.response_set_id = :response_set_1
            f.hidden = true
          end
        end
      end
      
    end
  end

end