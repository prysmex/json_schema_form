module JsonSchemaForm
  module Field
    class Static < ::JsonSchemaForm::Type::Null

      include ::JsonSchemaForm::Field::FieldMethods

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:static).filled(Types::True)
          required(:displayProperties).hash do
            required(:sort).filled(:integer)
          end
        end
      end

    end
  end
end