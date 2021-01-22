module JsonSchemaForm
  module Field
    class Static < ::JsonSchemaForm::JsonSchema::Null

      include ::JsonSchemaForm::Field::InstanceMethods

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:static).filled(Types::True)
          required(:displayProperties).hash do
            optional(:hiddenOnCreate).maybe(:bool)
            required(:sort).filled(:integer)
          end
        end
      end

    end
  end
end