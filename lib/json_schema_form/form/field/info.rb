module JsonSchemaForm
  module Field
    class Info < ::JsonSchemaForm::JsonSchema::Null

      include ::JsonSchemaForm::Field::InstanceMethods

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
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
            required(:kind).filled(:string)
            required(:useInfo).filled(:bool)
            required(:icon).filled(:string)
            required(:sort).filled(:integer)
            required(:hidden).filled(:bool)
          end
        end
      end

      ##############
      ###METHODS####
      ##############

      def migrate!
        if self.dig(:displayProperties, :pictures).nil?
          self.bury(:displayProperties, :pictures, [])
        end
      end

    end
  end
end