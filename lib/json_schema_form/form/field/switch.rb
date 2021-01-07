module JsonSchemaForm
  module Field
    class Switch < ::JsonSchemaForm::JsonSchema::Boolean

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
              required(:trueLabel).hash do
                optional(:es).maybe(:string)
                optional(:en).maybe(:string)
              end
              required(:falseLabel).hash do
                optional(:es).maybe(:string)
                optional(:en).maybe(:string)
              end
            end
            required(:visibility).hash do
              required(:label).filled(:bool)
            end
            required(:sort).filled(:integer)
            required(:hidden).filled(:bool)
            required(:useToggle).filled(:bool)
          end
        end
      end

      ##################
      #####METHODS######
      ##################

      def max_score
        1
      end

      def migrate!
      end

      def valid_for_locale?(locale = :es)
        super &&
          !self.dig(:displayProperties, :i18n, :trueLabel, locale).nil? &&
          !self.dig(:displayProperties, :i18n, :falseLabel, locale).nil?
      end

    end
  end
end