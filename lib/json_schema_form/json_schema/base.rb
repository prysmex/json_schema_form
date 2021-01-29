require 'super_hash'
require 'dry-schema'

module JsonSchemaForm
  module JsonSchema

    module ConditionalMethods
      
      # https://json-schema.org/understanding-json-schema/reference/conditionals.html
      def dependent_conditions
        if self.meta.dig(:parent, :allOf)
          (self.meta.dig(:parent, :allOf) || []).select do |condition|
            condition.dig(:if, :properties).keys.include?(self.key_name.to_sym)
          end
        # ToDo consider simple condition when 'if' is at same level as properties
        elsif self.meta.dig(:parent, :if)
          []
        else
          []
        end
      end

      def has_dependent_conditions?
        dependent_conditions.length > 0
      end

      def dependent_conditions_for_value(value)
        dependent_conditions.select do |condition|
          negated = !condition.dig(:if, :properties, self.key_name.to_sym, :not).nil?
          condition_type = if negated
            condition.dig(:if, :properties, self.key_name.to_sym, :not)
          else
            condition.dig(:if, :properties, self.key_name.to_sym)
          end

          match = case condition_type.keys[0]
          when :const
            # only return true for nil when condition_type[:const] == nil
            if value.nil? && condition_type[:const].nil?
              true
            else
              next false if value.nil?
              # simple comparisons from here on
              if self.is_a?(JsonSchemaForm::Field::TextInput)
                condition_type[:const].downcase == value.downcase
              else
                condition_type[:const] == value
              end
            end
          when :enum
            # only return true for nil when condition_type[:enum].include?(nil)
            if value.nil? && condition_type[:enum].include?(nil)
              true
            else
              next false if value.nil?
              # simple comparisons from here on
              if self.is_a?(JsonSchemaForm::Field::TextInput)
                condition_type[:enum].map(&:downcase).include?(value&.downcase)
              else
                condition_type[:enum].include?(value)
              end
            end
          end
          negated ? !match : match
        end
      end
      
    end

    class Base < ::SuperHash::Hasher

      instance_variable_set('@allow_dynamic_attributes', true)
      attr_reader :meta
      
      #Builder proc, receives hash and returns a JsonSchemaForm::JsonSchema::? class
      BUILDER = Proc.new do |obj, meta, options|
        # klass_name = "JsonSchemaForm::JsonSchema::#{obj[:type].to_s.split('_').collect(&:capitalize).join}"
        # klass = Object.const_get(klass_name)
        # type = Types.Constructor(klass) { |v| klass.new(v[:obj], v[:meta]) }
        # type[{obj: obj, meta: meta}]
        klass = case obj[:type]
        when 'string', :string
          JsonSchemaForm::JsonSchema::String
        when 'number', :number, 'integer', :integer
          JsonSchemaForm::JsonSchema::Number
        when 'boolean', :boolean
          JsonSchemaForm::JsonSchema::Boolean
        when 'array', :array
          JsonSchemaForm::JsonSchema::Array
        when 'object', :object
          JsonSchemaForm::JsonSchema::Object
        when 'null', :null
          JsonSchemaForm::JsonSchema::Null
        end

        #detect by other ways than 'type' property
        if klass.nil?
          if obj.has_key?(:properties)
            klass = JsonSchemaForm::JsonSchema::Object
          end
        end

        raise StandardError.new('builder conditions not met') if klass.nil?

        klass.new(obj, meta, options)
      end

      def self.inherited(klass)
        if [
            'JsonSchemaForm::JsonSchema::Array',
            'JsonSchemaForm::JsonSchema::Boolean',
            'JsonSchemaForm::JsonSchema::Null',
            'JsonSchemaForm::JsonSchema::Number',
            'JsonSchemaForm::JsonSchema::String'
        ].include?(klass.name)
          klass.include(ConditionalMethods)
        end
        super
      end
      
      def initialize(obj={}, meta={}, options={}, &block)
        @meta = meta
        super(obj, options, &block)
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