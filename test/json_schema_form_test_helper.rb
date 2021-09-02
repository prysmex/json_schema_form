require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/reporters'
require 'json_schema_form'
require_relative 'examples'
require 'byebug'

Minitest::Reporters.use!

module JsonSchemaFormTestHelper
  
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
      @new_hasher_class = Object.const_set('SampleSchema', Class.new(SchemaHash))
    end
  
    def teardown
      Object.send(:remove_const, 'SampleSchema')
    end
  end
  
end
