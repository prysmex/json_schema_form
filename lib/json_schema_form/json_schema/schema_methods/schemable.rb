module JsonSchema
  module SchemaMethods
    module Schemable

      # OBJECT_KEYS = [:properties, :required, :required, :propertyNames, :if, :then, :else, :additionalProperties, :minProperties, :maxProperties, :dependencies, :patternProperties]
      # STRING_KEYS = [:minLength, :maxLength, :pattern, :format, :enum, :const]
      # NUMBER_KEYS = [:multipleOf, :minimum, :maximum, :exclusiveMinimum, :exclusiveMaximum]
      # BOOLEAN_KEYS = []
      # ARRAY_KEYS = [:items, :contains, :additionalItems, :minItems, :maxItems, :uniqueItems]
      # NULL_KEYS = []

      attr_reader :meta

      def self.included(base)
        base.instance_variable_set('@allow_dynamic_attributes', true)

        base.attribute? :type, {
          type: (
            Types::String.enum('array','boolean','null','number','object','string') |
            Types::Array.constrained(min_size: 1).of(Types::String.enum('array','boolean','null','number','object','string'))
          )
        }
        # base.attribute? :'$id', {
        #   default: ->(data) { "##{self.meta[:path].join('/')}#{self.key_name}" }
        # }
      end
      
      def initialize(obj={}, options={})
        @meta = {
          parent: nil,
          path: [],
          is_subschema: false
        }.merge(options.delete(:meta) || {})

        super(obj, options)
      end

      # Returns an array of json-schema types, even when self[:type] is a string
      # @return [Array]
      def types
        self[:type].is_a?(::Array) ? self[:type] : [self[:type]] if self[:type]
      end

      # Iterates each parent yielding the current and next parent. 
      # It returns the current parent if block evaluates to true
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
          meta.dig(:parent, :required).include?(key_name)
        end
      end

      # Get name of key if nested inside properties or definitions by checking the path
      # {properties: {some_key: {}}} => 'some_key'
      def key_name
        attribute, key_name = self.meta[:path].last(2)
        if [:properties, :definitions].include?(attribute)
          key_name
        end
      end

      # https://json-schema.org/understanding-json-schema/reference/conditionals.html
      #ToDo missing parent if conditions
      # Returns all conditions that depend on the schema instance
      # @return [Nil, Array]
      def dependent_conditions
        key = self.key_name
        return if key.nil?
        parent_all_of = self.meta.dig(:parent, :allOf) || []
        
        parent_all_of.select do |condition|
          condition.dig(:if, :properties).keys.include?(key)
        end
      end

      # @return [Boolean] true if the schema instance has conditions that depend on it
      def has_dependent_conditions?
        (dependent_conditions || []).length > 0
      end

      # Selects dependent_conditions that evaluate to true based on a input value
      # The evaluation of the schema is not part of the scope of this gem, so a
      # block is yielded so a json-schema compliant method can evaluate it.
      # @param value [] value to evaluate
      # @return [Nil, Array] 
      def dependent_conditions_for_value(value, &block)
        dependent_conditions&.select do |condition|
          yield(condition[:if], value, self)
        end
      end

      # Hash of validations to be runned on a JSON-SCHEMA checker
      # ToDo make recursive
      # def validations

      #   vals = {
      #     required: required?,
      #     type: self.types,
      #     const: self[:const]
      #   }.compact

      #   #object
      #   if self.types.include?('object')
      #     vals[:properties] = self[:properties]&.inject({}) do |acum, (k,v)|
      #       acum[k] = v.validations
      #       acum
      #     end
      #   end

      #   #array
      #   if self.types.include?('array')
      #     vals = vals.merge({
      #       items: self&.[](:items)&.validations,
      #       contains: self&.[](:contains)&.validations,
      #       additionalItems: self[:additionalItems],
      #       minItems: self[:minItems],
      #       maxItems: self[:maxItems],
      #       uniqueItems: self[:uniqueItems]
      #     }.compact)
      #   end

      #   #string
      #   if self.types.include?('string')
      #     vals = vals.merge({
      #       minLength: self[:minLength],
      #       maxLength: self[:maxLength],
      #       pattern: self[:pattern],
      #       format: self[:format],
      #       enum: self[:enum]
      #     }.compact)
      #   end

      #   #number
      #   if self.types.include?('number')
      #     vals = vals.merge({
      #       multipleOf: self[:multiple_of],
      #       minimum: self[:minimum],
      #       maximum: self[:maximum],
      #       exclusiveMinimum: self[:exclusive_minimum],
      #       exclusiveMaximum: self[:exclusive_maximum],
      #       enum: self[:enum]
      #     }.compact)
      #   end

      # end

    end
  end
end