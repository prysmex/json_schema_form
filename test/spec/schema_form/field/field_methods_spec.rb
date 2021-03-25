require 'test_helper'

module FieldHelpers
  include TestHelper::Examples

  def get_field_klass_name
    self.class.name.sub('Test', '')
  end

  def get_field_klass
    Object.const_get("SchemaForm::Field::#{get_field_klass_name}")
  end

  def example_for_current_field_klass
    underscored_klass_name = get_field_klass_name.split(/(?=[A-Z])/).map(&:downcase).join('_')
    get_parsed_example("/schema_form/field/#{underscored_klass_name}.json")
  end

  # def asdf
  #   {
  #     properties: {},
  #     definitions: {
  #       :"__test_response_set_id__" => SchemaForm::ResponseSet.new(
  #         get_parsed_example("/schema_form/response_set.json")[:default]
  #       )
  #     }
  #   }
  # end

end

module BaseMethodsTests

  include FieldHelpers
  
  def test_i18n_label
    instance = get_field_klass.new({
      displayProperties: {
        i18n: {
          label: {
            es: "opciones"
          }
        }
      }
    })
    assert_equal 'opciones', instance.i18n_label
  end

  def test_valid_for_locale
    klass = get_field_klass

    if [SchemaForm::Field::Static, SchemaForm::Field::Switch, SchemaForm::Field::Slider].include?(klass)
      skip "Does not apply for klass #{klass}"
    end

    instance = klass.new({
      displayProperties: {
        i18n: {
          label: {
            es: "opciones",
            en: nil,
            de: ''
          }
        }
      }
    })
    assert_equal true, instance.valid_for_locale?(:es)
    assert_equal false, instance.valid_for_locale?(:en)
    assert_equal false, instance.valid_for_locale?(:de)
    assert_equal false, instance.valid_for_locale?(:random)
  end

  def test_errors_dont_raise_error
    get_field_klass.new().errors
    assert_equal true, true
  end

end

module ResponseSettableTests

  include FieldHelpers
  
  def test_response_set_id
    example = example_for_current_field_klass
    instance = get_field_klass.new(example)
    assert_equal '#/definitions/__test_response_set_id__', instance.response_set_id
  end
  
  def test_response_set
    example = example_for_current_field_klass
    hash = {
      properties: {},
      definitions: {
        :"__test_response_set_id__" => SchemaForm::ResponseSet.new({
          anyOf: [
            {
              const: 'test'
            }
          ]
        })
      }
    }
    instance = get_field_klass.new(example, {parent: hash})
    hash[:properties][:testprop] = instance
    refute_nil instance.response_set
  end

  def test_i18n_value
    example = example_for_current_field_klass
    hash = {
      properties: {},
      definitions: {
        :"__test_response_set_id__" => SchemaForm::ResponseSet.new({
          anyOf: [
            {
              const: 'test',
              displayProperties: {
                i18n: {
                  en: "score_1_en",
                  es: "score_1_en"
                }
              }
            }
          ]
        })
      }
    }
    instance = get_field_klass.new(example, {parent: hash})
    hash[:properties][:testprop] = instance
    assert_equal 'score_1_en', instance.i18n_value('test', :en)
  end

end