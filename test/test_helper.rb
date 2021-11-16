require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/reporters'
require 'json_schema_form'
require 'byebug'

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

  # Module used for testing schema classes, it creates/removes a new schema class that inherits from
  # `JSF::BaseHash`
  module SampleClassHooks
    def setup
      @sample_schema_class = Object.const_set('SampleSchema', Class.new(JSF::BaseHash))
      @sample_schema_class.include JSF::Core::Schemable
    end
  
    def teardown
      Object.send(:remove_const, 'SampleSchema')
    end
  end
  
end