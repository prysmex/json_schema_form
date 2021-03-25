require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/reporters'
require 'json_schema_form'
require 'json'

Minitest::Reporters.use!

module TestHelper

  JSON_SCHEMA_TYPES = [
    'array',
    'boolean',
    'null',
    'number',
    'object',
    'string'
  ].freeze

  module SampleClassHooks
    def setup
      @new_hasher_class = Object.const_set('SampleSchema', Class.new(SuperHash::Hasher))
    end
  
    def teardown
      Object.send(:remove_const, 'SampleSchema')
    end
  end
  
  module Examples

    def gem_directory_path
      File.expand_path(File.dirname(__FILE__)) + '/../test/examples'
    end
    
    def get_parsed_example(example_path)
      SuperHash::DeepKeysTransform.symbolize_recursive(
        JSON.parse(
          File.read(
            gem_directory_path + example_path
          )
        )
      )
    end

    def build_example_with_example_response(type)
      example_response_set = get_parsed_example('/schema_form/response_set.json')
      example_response_set[:anyOf].push(
        get_parsed_example('/schema_form/response.json')[type]
      )
      example_response_set
    end

  end

end