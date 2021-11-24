require 'test_helper'

class DocumentTest < Minitest::Test

  def test_can_set_any_key
    document = JSF::Forms::Document.new(some_key: 'value')
    assert_equal document[:some_key], 'value'
  end

  # without_keywords

  def test_without_keywords
    hash = JSF::Forms::Document.new(some_key: 'value', meta: {}).without_keywords
    assert_equal 1, hash.keys.size
    assert_equal 'some_key', hash.keys.first
  end

  # each_extras

  def test_each_extras_hash
    document = JSF::Forms::Document.new({
      some_key: 'value',
      shared_template: {
        prop_1: 1
      },
      meta: {
        extras: {
          some_key: {},
          other_key: {
            pictures: ['picture_1']
          },
          section: [
            {
              shared_template: {
                prop_1: {
                  pictures: ['picture_2']
                }
              }
            }
          ]
        }
      }
    })

    pictures = []
    document.each_extras_hash do |obj|
      pictures.concat(obj['pictures']) if obj.key?('pictures')
    end
    assert_equal ['picture_1', 'picture_2'], pictures
  end

end