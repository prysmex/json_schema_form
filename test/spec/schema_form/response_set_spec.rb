require 'test_helper'

class ResponseSetTest < Minitest::Test
  
  include TestHelper::Examples

  def parent_stub(is_inspection: false)
    inspection_stub = Object.new
    inspection_stub.define_singleton_method(:is_inspection) do
      is_inspection
    end
    inspection_stub
  end

  def test_valid_for_locale
    instance = SchemaForm::ResponseSet.new({
      type: 'string',
      isResponseSet: true,
      anyOf: [
        {
          type: 'string',
          const: 'option2501',
          displayProperties: {
            i18n: {
              en: 'Test 1',
              es: 'Prueba 1'
            }
          }
        },
        {
          type: 'string',
          const: 'option1233',
          displayProperties: {
            i18n: {
              en: nil,
              es: 'Prueba 2'
            }
          }
        }
      ]
    })
    assert_equal false, instance.valid_for_locale?(:en)
    assert_equal true, instance.valid_for_locale?(:es)
  end

  def test_default_example_is_valid
    hash = get_parsed_example('/../test/examples/schema_form/response_set.json')
    instance = SchemaForm::ResponseSet.new(hash)
    assert_empty instance.errors({}, self.parent_stub)
  end

end