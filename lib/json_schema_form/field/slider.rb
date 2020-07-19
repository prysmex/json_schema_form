module JsonSchemaForm
  module Field
    class Slider < ::JsonSchemaForm::Type::Number

      def validation_schema
        super.merge(
          Dry::Schema.JSON do
            #config.validate_keys = true
            required(:displayProperties).hash do
              required(:i18n).hash do
                required(:label).hash do
                  optional(:es).maybe(:string)
                  optional(:en).maybe(:string)
                end
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
        )
      end

    end
  end
end