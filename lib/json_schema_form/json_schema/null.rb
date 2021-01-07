module JsonSchemaForm
  module JsonSchema
    class Null < Base

      attribute :type, {
        default: ->(instance) { 'null' },
        type: Types::String.enum('null')
      }

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:type).filled(:string).value(included_in?: ['null'])
        end
      end

    end
  end
end