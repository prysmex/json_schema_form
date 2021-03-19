module JsonSchemaForm
  module SchemaMethods
    module Buildable

      def builder(attribute, obj, meta, options)
        self.class::BUILDER.call(attribute, obj, meta, options)
      end

      BUILDER = ->(attribute, obj, meta, options) {
        JsonSchemaForm::Schema.new(obj, meta, options)
      }

      ITEMS_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Array
          instance.class::ARRAY_PROC.call(attribute, instance, value, [attribute])
        when ::Hash
          instance.class::HASH_PROC.call(attribute, instance, value, [attribute])
        end
      }

      IF_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Hash
          instance.class::HASH_PROC.call(attribute, instance, value, [attribute])
        end
      }

      CONTAINS_TRANSFORM = IF_TRANSFORM
      THEN_TRANSFORM = IF_TRANSFORM
      ELSE_TRANSFORM = IF_TRANSFORM
      NOT_TRANSFORM = IF_TRANSFORM

      All_OF_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Array
          instance.class::ARRAY_PROC.call(attribute, instance, value, [attribute])
        end
      }
      ANY_OF_TRANSFORM = All_OF_TRANSFORM
      ONE_OF_TRANSFORM = All_OF_TRANSFORM

      ADDITIONAL_PROPERTIES_TRANSFORM = ->(instance, value, attribute) {
        case value
        when ::Hash
          instance.class::HASH_PROC.call(attribute, instance, value, [attribute])
        else
          value
        end
      }

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

      def self.included(base)

        ########
        #global#
        ########
        base.attribute? :if, transform: IF_TRANSFORM
        base.attribute? :then, transform: THEN_TRANSFORM
        base.attribute? :else, transform: ELSE_TRANSFORM
        base.attribute? :allOf, transform: All_OF_TRANSFORM
        base.attribute? :anyOf, transform: ANY_OF_TRANSFORM
        base.attribute? :oneOf, transform: ONE_OF_TRANSFORM
        base.attribute? :not, transform: NOT_TRANSFORM

        ########
        #object#
        ########
        base.attribute? :properties, transform: PROPERTIES_TRANSFORM
        base.attribute? :definitions, transform: DEFINITIONS_TRANSFORM
        base.attribute? :additionalProperties, transform: ADDITIONAL_PROPERTIES_TRANSFORM

        #######
        #array#
        #######
        base.attribute? :items, transform: ITEMS_TRANSFORM
        base.attribute? :contains, transform: CONTAINS_TRANSFORM
      end

    end
  end
end