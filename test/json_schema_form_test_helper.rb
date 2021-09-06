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

  # Module used for testing schema classes, it creates/removes a new schema class that inherits from
  # `JSF::BaseHash`
  module SampleClassHooks
    def setup
      @new_hasher_class = Object.const_set('SampleSchema', Class.new(JSF::BaseHash))
      @new_hasher_class.include JSF::Core::Schemable
    end
  
    def teardown
      Object.send(:remove_const, 'SampleSchema')
    end
  end
  
end
