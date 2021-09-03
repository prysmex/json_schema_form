module JsonSchema
  module StrictTypes

    module Array
      def self.included(base)
        base.include(JsonSchema::SchemaMethods::Arrayable)
        base.update_attribute 'type', {
          # required: true,
          type: Types::String.enum('array')
        }
      end
    end

    module Boolean
      def self.included(base)
        base.include(JsonSchema::SchemaMethods::Booleanable)
        base.update_attribute 'type', {
          # required: true,
          type: Types::String.enum('boolean')
        }
      end
    end

    module Null
      def self.included(base)
        base.include(JsonSchema::SchemaMethods::Nullable)
        base.update_attribute 'type', {
          # required: true,
          type: Types::String.enum('null')
        }
      end
    end

    module Number
      def self.included(base)
        base.include(JsonSchema::SchemaMethods::Numberable)
        base.update_attribute 'type', {
          # required: true,
          type: Types::String.enum('number')
        }
      end
    end

    module Object
      def self.included(base)
        base.include(JsonSchema::SchemaMethods::Objectable)
        base.update_attribute 'type', {
          # required: true,
          type: Types::String.enum('object')
        }
      end
    end

    module String
      def self.included(base)
        base.include(JsonSchema::SchemaMethods::Stringable)
        base.update_attribute 'type', {
          # required: true,
          type: Types::String.enum('string')
        }
      end
    end

  end
end