module JsonSchemaForm
  module Field
    class Slider < ::JsonSchemaForm::Type::Number

      include ::JsonSchemaForm::Field::FieldMethods

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          # required(:responseSetId) { int? | str? }
          required(:displayProperties).hash do
            required(:i18n).hash do
              required(:label).hash do
                optional(:es).maybe(:string)
                optional(:en).maybe(:string)
              end
              # ToDo create two types of sliders and remove this when only numbers
              required(:enum).hash do
                optional(:es).maybe(:hash)
                optional(:en).maybe(:hash)
              end
            end
            required(:visibility).hash do
              required(:label).filled(:bool)
            end
            required(:sort).filled(:integer)
            required(:hidden).filled(:bool)
            required(:useSlider).filled(:bool)
          end
        end
      end

      def schema_validation_hash
        json = super
        enum_locales = json.dig(:displayProperties, :i18n, :enum)
        enum_locales&.each do |lang, locales|
          locales&.clear
        end
        json
      end

    end
  end
end