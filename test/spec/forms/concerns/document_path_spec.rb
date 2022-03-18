require 'test_helper'

class FormTest < Minitest::Test

  def test_document_path
    form = JSF::Forms::FormBuilder.build() do

      # Add form in definitions
      add_shared_pair(
        db_id: 1,
        index: :prepend,
        definition: JSF::Forms::FormBuilder.build() do
          append_property(:shared_switch_1, example('switch')) do |f, key|
            append_conditional_property(:shared_switch_1_1, example('switch'), dependent_on: key, type: :const, value: true)
          end
        end
      )

      # Section
      append_property(:section, example('section')) do |f|
        f.form.instance_eval do
          append_property(:switch_2, example('switch'))
  
          # nested Section
          append_property(:section_1_3, example('section')) do |f|
            f.form.instance_eval do
              append_property(:switch_1_1_1, example('switch')) do |f, key|
                append_conditional_property(:switch_1_1_1, example('switch'), dependent_on: key, type: :const, value: true)
              end
            end
          end
        end
      end

      # Field
      append_property(:switch_1, example('switch')) do |f, key|
        append_conditional_property(:switch_1_1, example('switch'), dependent_on: key, type: :const, value: true) do |f, key, subform|
          subform.append_conditional_property(:switch_1_2, example('switch'), dependent_on: key, type: :const, value: true)
        end
      end

    end

    assert_equal ["switch_1"], form.dig(:properties, :switch_1).document_path
    assert_equal ["switch_1_1"], form.dig(:allOf, 0, :then, :properties, :switch_1_1).document_path
    assert_equal ["section"], form.dig(:properties, :section).document_path

    assert_raises(StandardError){form.dig(:properties, :section, :items, :properties, :switch_2).document_path}
    assert_raises(StandardError){form.dig(:properties, :section, :items, :properties, :section_1_3, :items, :properties, :switch_1_1_1).document_path}
    
    assert_equal ["shared_schema_template_1", "shared_switch_1"], form.dig(:definitions, :shared_schema_template_1, :properties, :shared_switch_1).document_path
    assert_equal ["shared_schema_template_1", "shared_switch_1_1"], form.dig(:definitions, :shared_schema_template_1, :allOf,  0, :then, :properties, :shared_switch_1_1).document_path
  end

end