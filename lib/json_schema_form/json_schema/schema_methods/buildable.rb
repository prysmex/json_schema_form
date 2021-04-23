module JsonSchema
  module SchemaMethods
    module Buildable

      def self.included(base)
        ###########
        #hash keys#
        ###########
        base.update_attribute :additionalProperties, transform: ADDITIONAL_PROPERTIES_TRANSFORM
        base.update_attribute :contains, transform: CONTAINS_TRANSFORM
        base.update_attribute :definitions, transform: DEFINITIONS_TRANSFORM
        base.update_attribute :dependencies, transform: DEPENDENCIES_TRANSFORM
        base.update_attribute :else, transform: ELSE_TRANSFORM
        base.update_attribute :if, transform: IF_TRANSFORM
        base.update_attribute :items, transform: ITEMS_TRANSFORM
        base.update_attribute :not, transform: NOT_TRANSFORM
        base.update_attribute :properties, transform: PROPERTIES_TRANSFORM
        base.update_attribute :then, transform: THEN_TRANSFORM
        
        ############
        #Array keys#
        ############
        base.update_attribute :allOf, transform: All_OF_TRANSFORM
        base.update_attribute :anyOf, transform: ANY_OF_TRANSFORM
        base.update_attribute :oneOf, transform: ONE_OF_TRANSFORM
      end

      def initialize(*args)
        @builder = nil
        super(*args)
      end

      def builder(attribute, obj, meta, options)
        if @builder
          @builder.call(attribute, obj, meta, options)
        else
          self.class.new(obj, meta, options)
        end
      end

      ###########
      #Hash keys#
      ###########
      HASH_PROC = ->(attribute, instance, hash, path) {
        instance.builder(
          attribute,
          hash,
          {
            parent: instance,
            is_subschema: true,
            path: (instance.meta[:path] || []) + path
          },
          {}#{skip_required_attrs: [:type]}
        )
      }

      ADDITIONAL_PROPERTIES_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Hash
          instance.class::HASH_PROC.call(attribute, instance, value, [attribute])
        else
          value
        end
      }

      CONTAINS_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Hash
          instance.class::HASH_PROC.call(attribute, instance, value, [attribute])
        end
      }

      DEFINITIONS_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Hash
          value.inject({}) do |acum, (name, definition)|
            acum[name] = instance.class::HASH_PROC.call(
              attribute, 
              instance,
              definition,
              [:definitions, name]
            )
            acum
          end
        end
      }

      DEPENDENCIES_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Hash
          value.inject({}) do |acum, (name, definition)|
            if definition.is_a?(::Hash)
              acum[name] = instance.class::HASH_PROC.call(
                attribute, 
                instance,
                definition,
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

      ITEMS_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Array
          instance.class::ARRAY_PROC.call(attribute, instance, value, [attribute])
        when ::Hash
          instance.class::HASH_PROC.call(attribute, instance, value, [attribute])
        end
      }

      NOT_TRANSFORM = CONTAINS_TRANSFORM

      PROPERTIES_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Hash
          value.inject({}) do |acum, (name, definition)|
            acum[name] = instance.class::HASH_PROC.call(
              attribute, 
              instance,
              definition,
              [:properties, name]
            )
            acum
          end
        end
      }

      THEN_TRANSFORM = CONTAINS_TRANSFORM

      ############
      #Array keys#
      ############
      
      ARRAY_PROC = ->(attribute, instance, array, path) {
        array.map.with_index do |definition, index|
          instance.builder(
            attribute,
            definition,
            {
              parent: instance,
              is_subschema: true,
              path: (instance.meta[:path] || []) + path + [index]
            },
            {}#{skip_required_attrs: [:type]}
          )
        end
      }

      All_OF_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Array
          instance.class::ARRAY_PROC.call(attribute, instance, value, [attribute])
        end
      }

      ANY_OF_TRANSFORM = All_OF_TRANSFORM

      ONE_OF_TRANSFORM = All_OF_TRANSFORM

    end
  end
end