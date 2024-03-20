# frozen_string_literal: true

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

      def self.included(base)
        base.instance_variable_set(:@allow_dynamic_attributes, true)
        base.include InstanceMethods
        base.extend ClassMethods

        base.attribute? 'type', {
          type: (
            Types::String.enum('array', 'boolean', 'null', 'number', 'object', 'string') |
            Types::Array.constrained(min_size: 1).of(Types::String.enum('array', 'boolean', 'null', 'number', 'object', 'string'))
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
        def set_strict_type(type_or_types)
          types = Array(type_or_types)

          update_attribute 'type', {
            # required: true,
            type: Types::String.enum(*types),
            default: ->(_data) { types.first }
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
        def initialize(obj = {}, options = {})
          @meta = {
            parent: nil,
            path: [],
            is_subschema: false
          }.merge(options[:meta] || {})

          super(obj, options)
        end

        # Returns an array of json-schema types, even when self[:type] is a single string
        #
        # @return [Array]
        def types
          return unless self[:type]

          self[:type].is_a?(::Array) ? self[:type] : [self[:type]]
        end

        # Iterates each parent yielding the current and next parent
        # It returns the current parent if block evaluates to true
        #
        # @param [Proc] block
        def find_parent
          parent = meta[:parent]
          return if parent.nil?

          loop do
            next_parent = parent.respond_to?(:meta) ? parent.meta[:parent] : nil
            break parent if yield(parent, next_parent)
            break unless parent = next_parent
          end
        end

        # Get the uppermost reachable parent by looping through the references in meta
        def root_parent
          find_parent { |_current, next_| next_.nil? }
        end

        # Checks if parent schema's 'properties' array contains they key of current subschema
        def required?
          meta.dig(:parent, :required).include?(key_name&.to_s) if meta.dig(:parent, :required)
        end

        # Get name of key if nested inside properties or $defs by checking the path
        # {properties: {some_key: {}}} => 'some_key'
        def key_name
          attribute, key_name = meta[:path].last(2)
          key_name if %i[properties $defs].include?(attribute&.to_sym)
        end

        # https://json-schema.org/understanding-json-schema/reference/conditionals.html
        # Returns all conditions that depend on the schema instance
        #
        # @todo missing parent if conditions
        #
        # @return [Nil, Array]
        def dependent_conditions
          key = key_name
          return if key.nil?

          parent_all_of = meta.dig(:parent, :allOf) || []

          parent_all_of.select do |condition|
            condition.dig(:if, :properties).keys.include?(key.to_s)
          end
        end

        # @return [Boolean] true if the schema instance has conditions that depend on it
        def has_dependent_conditions?
          (dependent_conditions || []).length > 0
        end

        # Selects dependent_conditions that evaluate to true based on a input value
        #
        # @param value [] value to evaluate
        # @return [Nil, Array]
        def dependent_conditions_for_value(value, &block)
          dependent_conditions&.select do |condition|
            if condition.respond_to?(:evaluate)
              condition.evaluate(value, &block)
            else
              yield(condition)
            end
          end
        end

        # # Finds property that it depends on
        # #
        # # @return [Nil, JSF::Forms::Field::*]
        # def depender
        #   condition = self
        #     &.meta&.dig(:parent)
        #     &.meta&.dig(:parent)

        #   return unless condition.respond_to?(:condition_property)
        #   condition.condition_property
        # end

      end

    end
  end
end