module JSF
  module Core
    
    # - contains all the base logic for any schema class
    # - sets the 'type' attribute that validates a valid json schema type
    # - support 'meta'
    #   - parent: support navigating to parent
    #   - is_subschema: boolean
    #   - path: absolute path to current schema
    #
    module Schemable
    
      # OBJECT_KEYS = ['properties', 'required', 'required', 'propertyNames', 'if', 'then', 'else', 'additionalProperties', 'minProperties', 'maxProperties', 'dependencies', 'patternProperties']
      # STRING_KEYS = ['minLength', 'maxLength', 'pattern', 'format', 'enum', 'const']
      # NUMBER_KEYS = ['multipleOf', 'minimum', 'maximum', 'exclusiveMinimum', 'exclusiveMaximum']
      # BOOLEAN_KEYS = []
      # ARRAY_KEYS = ['items', 'contains', 'additionalItems', 'minItems', 'maxItems', 'uniqueItems']
      # NULL_KEYS = []
    
      def self.included(base)
        base.instance_variable_set('@allow_dynamic_attributes', true)
        base.include InstanceMethods
        base.extend ClassMethods
    
        base.attribute? 'type', {
          type: (
            Types::String.enum('array','boolean','null','number','object','string') |
            Types::Array.constrained(min_size: 1).of(Types::String.enum('array','boolean','null','number','object','string'))
          )
        }
        # base.attribute? '$id', {
        #   default: ->(data) { "##{self.meta[:path].join('/')}#{self.key_name}" }
        # }
      end

      module ClassMethods
        
        # Updates the 'type' attribute by setting a mandatory value
        # Raises an error if not valid
        #
        # @param [String] type
        # @return [void]
        def set_strict_type(type)
          update_attribute 'type', {
            # required: true,
            type: Types::String.enum(type)
          }
        end
      end

      module InstanceMethods

        attr_reader :meta

        # Initialize and set meta
        #
        # @param [Hash] obj
        # @param [Hash] options SuperHash::Hasher options
        # @option options [Hash] :meta
        def initialize(obj={}, options={})
          @meta = {
            parent: nil,
            path: [],
            is_subschema: false
          }.merge(options.delete(:meta) || {})
      
          super(obj, options)
        end
      
        # Returns an array of json-schema types, even when self[:type] is a single string
        #
        # @return [Array]
        def types
          self[:type].is_a?(::Array) ? self[:type] : [self[:type]] if self[:type]
        end
      
        # Iterates each parent yielding the current and next parent
        # It returns the current parent if block evaluates to true
        #
        # @param [Proc] block
        def find_parent
          parent = self.meta[:parent]
          return if parent.nil?
          loop do
            next_parent = parent.respond_to?(:meta) ? parent.meta[:parent] : nil
            break parent if yield(parent, next_parent)
            break unless parent = next_parent
          end
        end
      
        # Get the uppermost reachable parent by looping through the references in meta
        def root_parent
          find_parent{|current, _next| _next.nil? }
        end
      
        # Checks if parent schema's 'properties' array contains they key of current subschema
        def required?
          if meta.dig(:parent, :required)
            meta.dig(:parent, :required).include?(key_name&.to_sym)
          end
        end
      
        # Get name of key if nested inside properties or definitions by checking the path
        # {properties: {some_key: {}}} => 'some_key'
        def key_name
          attribute, key_name = self.meta[:path].last(2)
          if [:properties, :definitions].include?(attribute&.to_sym)
            key_name
          end
        end
      
        # https://json-schema.org/understanding-json-schema/reference/conditionals.html
        # Returns all conditions that depend on the schema instance
        #
        # @todo missing parent if conditions
        #
        # @return [Nil, Array]
        def dependent_conditions
          key = self.key_name
          return if key.nil?
          parent_all_of = self.meta.dig(:parent, :allOf) || []
          
          parent_all_of.select do |condition|
            condition.dig(:if, :properties).keys.include?(key.to_s)
          end
        end
      
        # @return [Boolean] true if the schema instance has conditions that depend on it
        def has_dependent_conditions?
          (dependent_conditions || []).length > 0
        end
      
        # Selects dependent_conditions that evaluate to true based on a input value
        # The evaluation of the schema is not part of the scope of this gem, so a
        # block is yielded so a json-schema compliant method can evaluate it.
        #
        # @param value [] value to evaluate
        # @return [Nil, Array] 
        def dependent_conditions_for_value(value, &block)
          dependent_conditions&.select do |condition|
            yield(condition[:if], value, self)
          end
        end

      end
      
    end
  end
end