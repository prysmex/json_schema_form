module JsonSchemaForm
  module JsonSchema
    module Schemable

      # OBJECT_KEYS = [:properties, :required, :required, :propertyNames, :if, :then, :else, :additionalProperties, :minProperties, :maxProperties, :dependencies, :patternProperties]
      # STRING_KEYS = [:minLength, :maxLength, :pattern, :format, :enum, :const]
      # NUMBER_KEYS = [:multipleOf, :minimum, :maximum, :exclusiveMinimum, :exclusiveMaximum]
      # BOOLEAN_KEYS = []
      # ARRAY_KEYS = [:items, :contains, :additionalItems, :minItems, :maxItems, :uniqueItems]
      # NULL_KEYS = []

      attr_reader :meta
      attr_reader :types

      def self.included(base)
        base.instance_variable_set('@allow_dynamic_attributes', true)
      end
      
      def initialize(obj={}, meta=nil, options={}, &block)
        @meta = meta || {
          parent: nil,
          path: [],
          is_subschema: false
        }
        @types = obj[:type].is_a?(::Array) ? obj[:type] : [obj[:type]] if obj[:type]

        super(obj, options, &block)
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
        if meta.dig(:parent, :required)
          meta.dig(:parent, :required).include?(key_name)
        end
      end

      # ToDo this should be more robust
      def key_name
        self[:'$id']&.gsub(/^(.*[\\\/])/, '')
      end

      # https://json-schema.org/understanding-json-schema/reference/conditionals.html
      #ToDo missing parent if conditions
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
          yield(condition, value)
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