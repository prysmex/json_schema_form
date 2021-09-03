# Include this module to make your class 'buildable' (a recursive tree).
# It sets the SuperHash's attributes with a transform Proc for each key that may contain a subschema.

# It also defines a builder method (ultimately called by all Procs), to allow a single entry point to
# customize how an instance can 'build' its child subschemas. This is how SchemaForm::Form
# can easily customize how the schema tree is built.

# It is important to note that all Procs are built so that the 'builder' always receive the
# same arguments

module JsonSchema
  module SchemaMethods
    module Buildable

      def self.included(base)
        ###########
        #Hash keys#
        ###########
        base.update_attribute 'additionalProperties', transform: ADDITIONAL_PROPERTIES_TRANSFORM
        base.update_attribute 'contains', transform: CONTAINS_TRANSFORM
        base.update_attribute 'definitions', transform: DEFINITIONS_TRANSFORM
        base.update_attribute 'dependencies', transform: DEPENDENCIES_TRANSFORM
        base.update_attribute 'else', transform: ELSE_TRANSFORM
        base.update_attribute 'if', transform: IF_TRANSFORM
        base.update_attribute 'items', transform: ITEMS_TRANSFORM
        base.update_attribute 'not', transform: NOT_TRANSFORM
        base.update_attribute 'properties', transform: PROPERTIES_TRANSFORM
        base.update_attribute 'then', transform: THEN_TRANSFORM
        
        ############
        #Array keys#
        ############
        base.update_attribute 'allOf', transform: All_OF_TRANSFORM
        base.update_attribute 'anyOf', transform: ANY_OF_TRANSFORM
        base.update_attribute 'oneOf', transform: ONE_OF_TRANSFORM
      end

      def initialize(obj={}, options={})
        @builder = options.delete(:builder)
        super(obj, options)
      end

      # Called by attribute Procs. It instantiates a new object by calling the instance's '@builder'
      # proc if present, otherwise defaults to own class
      # @param attribute [Symbol] name of the key
      # @param subschema [Hash]
      # @param meta [Hash]
      # @param init_options [Hash] object initilization options
      def builder(attribute, subschema, meta, init_options={})
        if @builder
          @builder.call(attribute, subschema, self, init_options.merge(meta: meta))
        else
          self.class.new(subschema, init_options.merge(meta: meta))
        end
      end

      # Builds meta hash and calls builder method
      CORE_PROC = ->(attribute, value, instance, path) {
        path = (instance.meta[:path] || []) + path
        meta = {
          parent: instance,
          is_subschema: true,
          path: path.map{|i| i.is_a?(Symbol) ? i.to_s : i }
        }
        instance.builder( attribute, value, meta )
      }

      ############
      #Hash Procs#
      ############

      # SuperHash::Hasher transform Proc
      ADDITIONAL_PROPERTIES_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Hash
          instance.class::CORE_PROC.call(attribute, value, instance, [attribute])
        else
          value
        end
      }

      # SuperHash::Hasher transform Proc
      CONTAINS_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Hash
          instance.class::CORE_PROC.call(attribute, value, instance, [attribute])
        end
      }

      # SuperHash::Hasher transform Proc
      DEFINITIONS_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Hash
          value.inject({}) do |acum, (name, definition)|
            acum[name] = instance.class::CORE_PROC.call(
              attribute, 
              definition,
              instance,
              [:definitions, name]
            )
            acum
          end
        end
      }

      # SuperHash::Hasher transform Proc
      DEPENDENCIES_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Hash
          value.inject({}) do |acum, (name, definition)|
            if definition.is_a?(::Hash)
              acum[name] = instance.class::CORE_PROC.call(
                attribute, 
                definition,
                instance,
                [:dependencies, name]
              )
            else
              acum[name] = definition
            end
            acum
          end
        end
      }

      ELSE_TRANSFORM = CONTAINS_TRANSFORM

      IF_TRANSFORM = CONTAINS_TRANSFORM

      # SuperHash::Hasher transform Proc
      ITEMS_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Array
          value.map.with_index do |definition, index|
            instance.class::CORE_PROC.call(attribute, definition, instance, [attribute, index])
          end
        when ::Hash
          instance.class::CORE_PROC.call(attribute, value, instance, [attribute])
        end
      }

      NOT_TRANSFORM = CONTAINS_TRANSFORM

      # SuperHash::Hasher transform Proc
      PROPERTIES_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Hash
          value.inject({}) do |acum, (name, definition)|
            acum[name] = instance.class::CORE_PROC.call(
              attribute, 
              definition,
              instance,
              [:properties, name]
            )
            acum
          end
        end
      }

      THEN_TRANSFORM = CONTAINS_TRANSFORM

      #############
      #Array Procs#
      #############

      # SuperHash::Hasher transform Proc
      All_OF_TRANSFORM = ->(attribute, value, instance) {
        case value
        when ::Array
          value.map.with_index do |definition, index|
            instance.class::CORE_PROC.call(attribute, definition, instance, [attribute, index])
          end
        end
      }

      ANY_OF_TRANSFORM = All_OF_TRANSFORM

      ONE_OF_TRANSFORM = All_OF_TRANSFORM

    end
  end
end