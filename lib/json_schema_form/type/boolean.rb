module JsonSchemaForm
  module Type
    class Boolean < Base

      attribute :type, {
        type: Types::String.enum('boolean')
      }

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:type).filled(:string).value(included_in?: ['boolean'])
        end
      end

    end
  end
end