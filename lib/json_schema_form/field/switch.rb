module JsonSchemaForm
  module Field
    class Switch < ::JsonSchemaForm::Type::Boolean

      ##################
      #####METHODS######
      ##################

      include ::JsonSchemaForm::Field::FieldMethods

      def max_score
        1
      end

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:displayProperties).hash do
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

    end
  end
end