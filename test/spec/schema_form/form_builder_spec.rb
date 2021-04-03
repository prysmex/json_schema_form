require 'json_schema_form_test_helper'

class FormbuilderTest < Minitest::Test

  def test_something
    form = SchemaForm::FormBuilder.build() do

      add_response_set(:response_set_1, example('response_set')).tap do |response_set|
        response_set.add_response(example('response')[:default]).tap do |r|
          r[:const] = 'option1'
          r[:score] = 0
        end
        response_set.add_response(example('response')[:default]).tap do |r|
          r[:const] = 'option2'
          r[:score] = 2
        end
        response_set.add_response(example('response')[:default]).tap do |r|
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
  
  # def test_asdf
  #   hash = SchemaForm::FormBuilder.build do
  #     add_property(:level1_prop1,
  #       example('checkbox').tap { |h|
  #         SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :en, 'Some nice label')
  #         SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :es, 'Un buen titulo')
  #         SuperHash::Utils.bury(h, :displayProperties, :hidden, true)
  #       },
  #       {required: true}
  #     )
  #     add_conditional_property(:level2_prop1, :level1_prop1, example('checkbox'), :const, 'test') do |f|
  #       f.add_property(:level2_prop2,
  #         example('checkbox').tap { |h|
  #           SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :en, 'Some nice label 2')
  #           SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :es, 'Un buen titulo 2')
  #           SuperHash::Utils.bury(h, :displayProperties, :hidden, true)
  #         },
  #         {required: true}
  #       )
  #       f.add_conditional_property(:level3_prop1, :level2_prop2, example('checkbox'), :const, 'test') do |f|
  #         f.add_property(:level3_prop2,
  #           example('checkbox').tap { |h|
  #             SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :en, 'Some nice label 3')
  #             SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :es, 'Un buen titulo 3')
  #             SuperHash::Utils.bury(h, :displayProperties, :hidden, true)
  #           },
  #           {required: false}
  #         )
  #       end
  #     end
  #   end
  # end


end