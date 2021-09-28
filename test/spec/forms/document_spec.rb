require 'json_schema_form_test_helper'

class DocumentTest < Minitest::Test

  def test_can_set_any_key
    document = JSF::Forms::Document.new(some_key: 'value')
    assert_equal document[:some_key], 'value'
  end

  # without_keywords

  def test_without_keywords
    hash = JSF::Forms::Document.new(some_key: 'value', extras: {}, meta: {}).without_keywords
    assert_equal 1, hash.keys.size
    assert_equal 'some_key', hash.keys.first
  end

  # property_keys

  def test_property_keys
    document = JSF::Forms::Document.new({
      some_key: 'value',
      other_key: 'test',
      shared_template: {
        prop_1: 1
      }
    })

    assert_equal 3, document.property_keys.size
    assert_equal ['some_key', 'other_key', 'prop_1'], document.property_keys
  end

  # set_missing_extras

  def test_set_missing_extras
    document = JSF::Forms::Document.new(some_key: 'value', shared: { prop_1: 1 })
    document.set_missing_extras

    expected = "{\"some_key\"=>{\"pictures\"=>[], \"score\"=>nil, \"failed\"=>nil, \"notes\"=>nil, \"report_ids\"=>[]}, \"shared\"=>{\"prop_1\"=>{\"pictures\"=>[], \"score\"=>nil, \"failed\"=>nil, \"notes\"=>nil, \"report_ids\"=>[]}}}"
    assert_equal expected, document[:extras].to_s
  end

  # set_missing_meta

  def test_set_missing_meta
    document = JSF::Forms::Document.new(some_key: 'value', shared: { prop_1: 1 })
    document.set_missing_meta

    expected = "{\"some_key\"=>{\"coordinates\"=>{}, \"timestamp\"=>nil}, \"shared\"=>{\"prop_1\"=>{\"coordinates\"=>{}, \"timestamp\"=>nil}}}"
    assert_equal expected, document[:meta].to_s
  end

  # each_extras

  def test_each_extras
    document = JSF::Forms::Document.new({
      some_key: 'value',
      shared_template: {
        prop_1: 1
      },
      extras: {
        some_key: {},
        other_key: { pictures: [] },
        shared_template: {
          prop_1: {}
        }
      }
    })

    keys = []
    document.each_extras{|k,v| keys.push(k) }
    assert_equal ['some_key', 'other_key', 'prop_1'], keys
  end

  # each_meta

  def test_each_meta
    document = JSF::Forms::Document.new({
      some_key: 'value',
      shared_template: {
        prop_1: 1
      },
      meta: {
        some_key: {},
        other_key: { timestamp: 'some timestamp' },
        shared_template: {
          prop_1: {}
        }
      }
    })

    keys = []
    document.each_meta{|k,v| keys.push(k) }
    assert_equal ['some_key', 'other_key', 'prop_1'], keys
  end

end