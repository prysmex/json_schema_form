module JsonSchemaForm
  module Field
    class Header < ::SuperHash::Hasher

      include JsonSchemaForm::JsonSchema::Schemable
      include JsonSchemaForm::Field::StrictTypes::Null
      include JsonSchemaForm::JsonSchema::Validatable
      include ::JsonSchemaForm::Field::InstanceMethods

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema
        Dry::Schema.define(parent: super) do
          required(:displayProperties).hash do
            required(:pictures).value(:array?).array(:str?)
            required(:i18n).hash do
              required(:label).hash do
                optional(:es).maybe(:string)
                optional(:en).maybe(:string)
              end
            end
            required(:visibility).hash do
              required(:label).filled(:bool)
            end
            required(:sort).filled(:integer)
            required(:hidden).filled(:bool)
            required(:useHeader).filled(:bool)
            required(:level).filled(Types::Integer.constrained(lteq: 2))
          end
        end
      end

      ##############
      ###METHODS####
      ##############

      def migrate!
      end

    end
  end
end