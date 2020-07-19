module JsonSchemaForm
  module Type
    class Null < Base

      # attribute :type, {
      #   type: Types::String.enum('null')
      # }

      def validation_schema
        super.merge(
          Dry::Schema.JSON do
            #config.validate_keys = true
            required(:type).filled(:string).value(included_in?: ['null'])
          end
        )
      end

    end
  end
end