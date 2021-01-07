module JsonSchemaForm
  module JsonSchema
    class Number < Base

      attribute :type, {
        default: ->(instance) { 'number' },
        type: Types::String.enum('number')
      }

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:type).filled(:string).value(included_in?: ['number'])
          optional(:multipleOf).filled(:integer)
          optional(:minimum).filled(:integer)
          optional(:maximum).filled(:integer)
          optional(:exclusiveMinimum).filled(:integer)
          optional(:exclusiveMaximum).filled(:integer)
          optional(:enum) #todo value type
        end
      end

      def validations
        super.merge({
          multipleOf: self[:multiple_of],
          minimum: self[:minimum],
          maximum: self[:maximum],
          exclusiveMinimum: self[:exclusive_minimum],
          exclusiveMaximum: self[:exclusive_maximum],
          enum: self[:enum]
        }).compact
      end

    end
  end
end