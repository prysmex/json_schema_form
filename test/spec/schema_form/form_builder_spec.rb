require 'json_schema_form_test_helper'

class FormbuilderTest < Minitest::Test
  
  def test_asdf
    hash = SchemaForm::FormBuilder.build do
      add_property(:level1_prop1,
        example('checkbox').tap { |h|
          SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :en, 'Some nice label')
          SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :es, 'Un buen titulo')
          SuperHash::Utils.bury(h, :displayProperties, :hidden, true)
        },
        {required: true}
      )
      add_conditional_property(:level2_prop1, :level1_prop1, example('checkbox'), :const, 'test') do |f|
        f.add_property(:level2_prop2,
          example('checkbox').tap { |h|
            SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :en, 'Some nice label 2')
            SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :es, 'Un buen titulo 2')
            SuperHash::Utils.bury(h, :displayProperties, :hidden, true)
          },
          {required: true}
        )
        f.add_conditional_property(:level3_prop1, :level2_prop2, example('checkbox'), :const, 'test') do |f|
          f.add_property(:level3_prop2,
            example('checkbox').tap { |h|
              SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :en, 'Some nice label 3')
              SuperHash::Utils.bury(h, :displayProperties, :i18n, :label, :es, 'Un buen titulo 3')
              SuperHash::Utils.bury(h, :displayProperties, :hidden, true)
            },
            {required: false}
          )
        end
      end
    end
    puts hash
  end

  # def test_builder
  #   #examples
  #   checkbox_example = JsonSchemaForm::SchemaFormExamples.checkbox
  #   switch_example = JsonSchemaForm::SchemaFormExamples.switch
  #   date_input_example = JsonSchemaForm::SchemaFormExamples.date_input

  #   form = SchemaForm::Form.new()

  #   form.add_property(:level1_prop1, checkbox_example, {required: true})

  #   form.instance_eval do

  #     add_property :level1_prop1, checkbox_example, {required: true}
  #     add_property :level1_prop2, switch_example, {required: true}
  #     add_property :level1_prop3, date_input_example, {required: true}
  #     add_conditional_property(:level2_prop1, :level1_prop1, checkbox_example, :const, 'test') do
  #       add_property :level2_prop2, checkbox_example, {required: true}
  #       add_property :level2_prop3, checkbox_example, {required: true}
  #       add_conditional_property(:level3_prop1, :level2_prop1, checkbox_example, :const, 'test') do
  #         add_property :level3_prop2, checkbox_example, {required: true}
  #         add_property :level3_prop3, checkbox_example, {required: true}
  #         add_conditional_property(:level4_prop1, :level3_prop1, checkbox_example, :const, 'test') do
  #           add_property :level4_prop2, checkbox_example, {required: true}
  #           add_property :level4_prop3, checkbox_example, {required: true}
  #         end
  #       end
  #     end

  #   end

  #   puts form

  # end

end