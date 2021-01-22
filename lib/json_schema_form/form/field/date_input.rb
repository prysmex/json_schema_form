module JsonSchemaForm
  module Field
    class DateInput < ::JsonSchemaForm::JsonSchema::String

      include ::JsonSchemaForm::Field::InstanceMethods

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:displayProperties).hash do
            optional(:hiddenOnCreate).maybe(:bool)
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