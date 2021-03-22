module JsonSchemaForm
  module StrictTypes

    module Array
      def self.included(base)
        base.include(JsonSchemaForm::SchemaMethods::Arrayable)
        base.update_attribute :type, {
          type: Types::String.enum('array')
        }
      end
    end

    module String
      def self.included(base)
        base.include(JsonSchemaForm::SchemaMethods::Stringable)
        base.update_attribute :type, {
          type: Types::String.enum('string')
        }
      end
    end

    module Boolean
      def self.included(base)
        base.include(JsonSchemaForm::SchemaMethods::Booleanable)
        base.update_attribute :type, {
          type: Types::String.enum('boolean')
        }
      end
    end

    module Null
      def self.included(base)
        base.include(JsonSchemaForm::SchemaMethods::Nullable)
        base.update_attribute :type, {
          type: Types::String.enum('null')
        }
      end
    end

    module Number
      def self.included(base)
        base.include(JsonSchemaForm::SchemaMethods::Numberable)
        base.update_attribute :type, {
          type: Types::String.enum('number')
        }
      end
    end

    module Object
      def self.included(base)
        base.include(JsonSchemaForm::SchemaMethods::Objectable)
        base.update_attribute :type, {
          type: Types::String.enum('object')
        }
        base.update_attribute :properties, default: ->(instance) { {}.freeze }
        base.update_attribute :required, default: ->(instance) { [].freeze }
        base.update_attribute :allOf, default: ->(instance) { [].freeze }
      end
    end

  end
end