require 'super_hash'
require 'dry-schema'

module JsonSchemaForm
  module JsonSchema

    class Base < ::SuperHash::Hasher

      instance_variable_set('@allow_dynamic_attributes', true)
      attr_reader :meta
      
      #Builder proc, receives hash and returns a JsonSchemaForm::Type::? class
      BUILDER = Proc.new do |obj, meta|
        # klass_name = "JsonSchemaForm::Type::#{obj[:type].to_s.split('_').collect(&:capitalize).join}"
        # klass = Object.const_get(klass_name)
        # type = Types.Constructor(klass) { |v| klass.new(v[:obj], v[:meta]) }
        # type[{obj: obj, meta: meta}]
        klass = case obj[:type]
        when 'string', :string
          JsonSchemaForm::Type::String
        when 'number', :number, 'integer', :integer
          JsonSchemaForm::Type::Number
        when 'boolean', :boolean
          JsonSchemaForm::Type::Boolean
        when 'array', :array
          JsonSchemaForm::Type::Array
        when 'object', :object
          JsonSchemaForm::Type::Object
        when 'null', :null
          JsonSchemaForm::Type::Null
        end

        #detect by other ways than 'type' property
        if klass.nil?
          if obj.has_key?(:properties)
            klass = JsonSchemaForm::Type::Object
          end
        end

        raise StandardError.new('builder conditions not met') if klass.nil?

        klass.new(obj, meta)
      end
      
      def initialize(obj, meta={}, &block)
        @meta = meta
        super(obj, &block)
      end

      attribute :type, {
        type: Types::String.enum('array','boolean','null','number','object','string')
      }
      attribute? :'$id', {
        default: ->(instance) { 'http://example.com/example.json' }
      }
      attribute? :'$schema', {
        default: ->(instance) { 'http://json-schema.org/draft-07/schema#' }
      }

      # Base dry-schema instance to validate data with.
      def validation_schema
        Dry::Schema.JSON do
          # config.validate_keys = true
          required(:type).filled(:string).value(included_in?: [
            'array','boolean','null','number','object','string'
          ])
          required(:'$id').filled(:string)
          required(:'$schema').filled(:string)
          optional(:title).maybe(:string)
          optional(:description).maybe(:string)
          optional(:default)
          optional(:examples)
        end
      end

      # JSON to be validated with 'validation_schema'
      # This is required because Dry::Schema.JSON has
      # no way to implement a validation for dynamic keys in arrays
      def schema_validation_hash
        Marshal.load(Marshal.dump(self))# new reference
      end

      # True when no errors returned from schema of no schema is present
      def valid_with_schema?
        schema_errors.empty?
      end

      #Returns a hash of errors if a validation_schema is present
      def schema_errors
        schema = validation_schema
        if schema
          schema.(schema_validation_hash).errors.to_h.merge({})
        else
          {}
        end
      end

      def key_name
        self[:'$id']&.gsub(/^(.*[\\\/])/, '')
      end

      # used for properties, returns true if it is required
      # by a parent object
      def required?
        if meta.dig(:parent, :type) == 'object'
          meta.dig(:parent, :required).include?(key_name)
        end
      end

      # Hash of validations to be runned on a JSON-SCHEMA checker
      def validations
        {
          required: required?
        }
      end

      private

    end
  end
end