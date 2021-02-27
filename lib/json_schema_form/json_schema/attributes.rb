module JsonSchemaForm
  module JsonSchema
    module Attributes

      def builder(attribute, obj, meta, options)
        self.class::BUILDER.call(attribute, obj, meta, options)
      end

      BUILDER = ->(attribute, obj, meta, options) {
        JsonSchemaForm::JsonSchema::Schema.new(obj, meta, options)
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
        base.attribute? :type, {
          type: (
            Types::String.enum('array','boolean','null','number','object','string') |
            Types::Array.constrained(min_size: 1).of(Types::String.enum('array','boolean','null','number','object','string'))
          )
        }
        base.attribute? :'$id', {
          # default: ->(instance) { 'http://example.com/example.json' }
        }
        base.attribute? :'$schema', {
          # default: ->(instance) { 'http://json-schema.org/draft-07/schema#' }
        }
        base.attribute? :if, transform: IF_TRANSFORM#, type: Types::Hash
        base.attribute? :then, transform: THEN_TRANSFORM#, type: Types::Hash
        base.attribute? :else, transform: ELSE_TRANSFORM#, type: Types::Hash
        base.attribute? :allOf, transform: All_OF_TRANSFORM#, type: Types::Array
        base.attribute? :not, transform: NOT_TRANSFORM#, type: Types::Array

        ########
        #object#
        ########
        base.attribute? :required#, type: Types::Array
        base.attribute? :properties, transform: PROPERTIES_TRANSFORM#, type: Types::Hash
        base.attribute? :definitions, transform: DEFINITIONS_TRANSFORM#, type: Types::Hash

        #######
        #array#
        #######
        base.attribute? :items, {
          # type: (Types::Array | Types::Hash),
          transform: ITEMS_TRANSFORM
        }
        base.attribute? :contains, {
          # type: (Types::Array | Types::Hash),
          transform: CONTAINS_TRANSFORM
        }
      end

    end
  end
end