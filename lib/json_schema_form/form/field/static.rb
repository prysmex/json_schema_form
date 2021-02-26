module JsonSchemaForm
  module Field
    class Static < ::SuperHash::Hasher

      include JsonSchemaForm::JsonSchema::Schemable
      include JsonSchemaForm::Field::StrictTypes::Null
      include JsonSchemaForm::JsonSchema::Validatable
      include ::JsonSchemaForm::Field::InstanceMethods

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema
        Dry::Schema.define(parent: super) do
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