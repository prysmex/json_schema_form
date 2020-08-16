module JsonSchemaForm
  module Field
    class NumberInput < ::JsonSchemaForm::JsonSchema::Number

      include ::JsonSchemaForm::Field::InstanceMethods

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:displayProperties).hash do
            required(:pictures).array(:string)
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
        if self.root_form[:schemaFormVersion].nil?
          self[:pictures] = []
        end
      end

    end
  end
end