module JsonSchemaForm
  module Field
    class Static < ::JsonSchemaForm::Type::Null

      def validation_schema
        super.merge(
          Dry::Schema.JSON do
            #config.validate_keys = true
            required(:static).filled(Types::True)
            required(:displayProperties).hash do
              required(:sort).filled(:integer)
            end
          end
        )
      end

    end
  end
end