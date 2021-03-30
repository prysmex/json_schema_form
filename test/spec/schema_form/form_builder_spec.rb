require 'json_schema_form_test_helper'

class FormbuilderTest < Minitest::Test
  
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