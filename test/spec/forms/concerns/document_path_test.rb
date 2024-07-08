# frozen_string_literal: true

require 'test_helper'

class FormTest < Minitest::Test

  def test_document_path
    shared_ref = nil
    form = JSF::Forms::FormBuilder.build do
      # Add form in $defs
      shared_ref = add_shared_pair(
        db_id: 1,
        index: :prepend,
        definition: JSF::Forms::FormBuilder.build do
          append_property(:shared_switch_1, example('switch')) do
            append_property(:shared_switch_1_1, example('switch'), type: :const, value: true)
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
              append_property(:switch_1_1_1, example('switch')) do
                append_property(:switch_1_1_2, example('switch'), type: :const, value: true)
              end
            end
          end
        end
      end

      # Field
      append_property(:switch_1, example('switch')) do
        append_property(:switch_1_1, example('switch'), type: :const, value: true) do
          append_property(:switch_1_2, example('switch'), type: :const, value: true)
        end
      end
    end

    assert_equal ['switch_1'], form.dig(:properties, :switch_1).document_path
    assert_equal ['switch_1_1'], form.dig(:allOf, 0, :then, :properties, :switch_1_1).document_path
    assert_equal ['switch_1_2'], form.dig(:allOf, 0, :then, :allOf, 0, :then, :properties, :switch_1_2).document_path

    assert_equal ['section'], form.dig(:properties, :section).document_path

    assert_raises(StandardError) { form.dig(:properties, :section, :items, :properties, :switch_2).document_path }
    assert_raises(StandardError) { form.dig(:properties, :section, :items, :properties, :section_1_3, :items, :properties, :switch_1_1_1).document_path }

    # single value section_indices
    assert_equal ['section', 0, 'switch_2'], form.dig(:properties, :section, :items, :properties, :switch_2).document_path(section_indices: 0)
    assert_equal ['section', 0, 'section_1_3', 0, 'switch_1_1_1'], form.dig(:properties, :section, :items, :properties, :section_1_3, :items, :properties, :switch_1_1_1).document_path(section_indices: 0)
    assert_equal ['section', 0, 'section_1_3', 0, 'switch_1_1_2'], form.dig(:properties, :section, :items, :properties, :section_1_3, :items, :allOf, 0, :then, :properties, :switch_1_1_2).document_path(section_indices: 0)

    # section_indices as array
    assert_equal ['section', 1, 'section_1_3', 2, 'switch_1_1_1'], form.dig(:properties, :section, :items, :properties, :section_1_3, :items, :properties, :switch_1_1_1).document_path(section_indices: [1, 2])

    ref_key = shared_ref.key_name
    prop_key = form.properties.find { |_k, v| v.is_a?(JSF::Forms::Field::Shared) }&.first

    assert_equal [prop_key, 'shared_switch_1'], form.dig(:$defs, ref_key, :properties, :shared_switch_1).document_path
    assert_equal [prop_key, 'shared_switch_1_1'], form.dig(:$defs, ref_key, :allOf, 0, :then, :properties, :shared_switch_1_1).document_path
  end

end