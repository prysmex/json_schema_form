require 'super_hash'
require 'dry-schema'

module JsonSchemaForm
  module JsonSchema

    class Base < ::SuperHash::Hasher

      instance_variable_set('@allow_dynamic_attributes', true)
      attr_reader :meta

      OBJECT_KEYS = [:properties, :required, :required, :propertyNames, :if, :then, :else, :additionalProperties, :minProperties, :maxProperties, :dependencies, :patternProperties]
      STRING_KEYS = [:minLength, :maxLength, :pattern, :format, :enum, :const]
      NUMBER_KEYS = [:multipleOf, :minimum, :maximum, :exclusiveMinimum, :exclusiveMaximum]
      BOOLEAN_KEYS = []
      ARRAY_KEYS = [:items, :contains, :additionalItems, :minItems, :maxItems, :uniqueItems]
      NULL_KEYS = []
      
      #Builder proc, receives hash and returns a JsonSchemaForm::JsonSchema::? class
      BUILDER = Proc.new do |obj, meta, options|
        # klass_name = "JsonSchemaForm::JsonSchema::#{obj[:type].to_s.split('_').collect(&:capitalize).join}"
        # klass = Object.const_get(klass_name)
        # type = Types.Constructor(klass) { |v| klass.new(v[:obj], v[:meta]) }
        # type[{obj: obj, meta: meta}]
        klass = case obj[:type]
        when 'object', :object
          JsonSchemaForm::JsonSchema::Object
        when 'string', :string
          JsonSchemaForm::JsonSchema::String
        when 'number', :number, 'integer', :integer
          JsonSchemaForm::JsonSchema::Number
        when 'boolean', :boolean
          JsonSchemaForm::JsonSchema::Boolean
        when 'array', :array
          JsonSchemaForm::JsonSchema::Array
        when 'null', :null
          JsonSchemaForm::JsonSchema::Null
        end

        #detect by other ways than 'type' property
        if klass.nil?
          klass = if OBJECT_KEYS.find{|k| obj.key?(k)}
            JsonSchemaForm::JsonSchema::Object
          elsif STRING_KEYS.find{|k| obj.key?(k)}
            JsonSchemaForm::JsonSchema::STRING
          elsif NUMBER_KEYS.find{|k| obj.key?(k)}
            JsonSchemaForm::JsonSchema::NUMBER
          elsif BOOLEAN_KEYS.find{|k| obj.key?(k)}
            JsonSchemaForm::JsonSchema::BOOLEAN
          elsif ARRAY_KEYS.find{|k| obj.key?(k)}
            JsonSchemaForm::JsonSchema::ARRAY
          elsif NULL_KEYS.find{|k| obj.key?(k)}
            JsonSchemaForm::JsonSchema::NULL
          end
        end

        raise StandardError.new('builder conditions not met') if klass.nil?

        klass.new(obj, meta, options)
      end

      # https://json-schema.org/understanding-json-schema/reference/conditionals.html
      def dependent_conditions
        parent_all_of = self.meta.dig(:parent, :allOf) || []
        
        parent_all_of.select do |condition|
          condition.dig(:if, :properties).keys.include?(self.key_name.to_sym)
        end
      end

      def has_dependent_conditions?
        dependent_conditions.length > 0
      end

      def dependent_conditions_for_value(value, &block)
        dependent_conditions.select do |condition|
          new_value = if value.is_a?(::Hash) ||value.is_a?(::Array)
            SuperHash::DeepKeysTransform.strigify_recursive(value)
          else
            value
          end
          yield(condition, value)
        end
      end
      
      def initialize(obj={}, meta={}, options={}, &block)
        @meta = meta
        super(obj, options, &block)
      end

      attribute? :type, {
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

      # get the uppermost parent
      def root_parent
        parent = meta[:parent]
        loop do
          next_parent = parent.meta[:parent]
          break if next_parent.nil?
          parent = next_parent
        end
        parent
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