module JsonSchemaForm
  module Field
    module StrictTypes

      module Array
        def self.included(base)
          base.include(JsonSchemaForm::JsonSchema::Arrayable)
          base.update_attribute :type, {
            type: Types::String.enum('array')
          }
        end
      end

      module String
        def self.included(base)
          base.include(JsonSchemaForm::JsonSchema::Stringable)
          base.update_attribute :type, {
            type: Types::String.enum('string')
          }
        end
      end

      module Boolean
        def self.included(base)
          base.include(JsonSchemaForm::JsonSchema::Booleanable)
          base.update_attribute :type, {
            type: Types::String.enum('boolean')
          }
        end
      end

      module Null
        def self.included(base)
          base.include(JsonSchemaForm::JsonSchema::Nullable)
          base.update_attribute :type, {
            type: Types::String.enum('null')
          }
        end
      end

      module Number
        def self.included(base)
          base.include(JsonSchemaForm::JsonSchema::Numberable)
          base.update_attribute :type, {
            type: Types::String.enum('number')
          }
        end
      end

      module Object
        def self.included(base)
          base.include(JsonSchemaForm::JsonSchema::Objectable)
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
end