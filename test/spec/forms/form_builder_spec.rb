require 'json_schema_form_test_helper'

class FormbuilderTest < Minitest::Test

  def test_examples
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
    
      append_property(:select1, example('select'), {required: true}).tap do |field|
        field.response_set_id = :response_set_1
      end
    
      #por separado
      append_conditional_property :depedendent_select1, example('select'), dependent_on: :select1, type: :const, value: 'option1'
      append_conditional_property :depedendent_select2, example('select'), dependent_on: :select1, type: :enum, value: ['option1']
    
      #nested
      append_conditional_property(:depedendent_select3, example('select'), dependent_on: :select1, type: :const, value: 'option2') do |form, field|
        field.response_set_id = :response_set_1
        field.hidden = true
        form.prepend_property(:depedendent_select4, example('select'), {required: true}).tap do |field|
          field.response_set_id = :response_set_1
          field.hidden = true
        end
      end
    
    end
  end

end