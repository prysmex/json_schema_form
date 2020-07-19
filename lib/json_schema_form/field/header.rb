module JsonSchemaForm
  module Field
    class Header < ::JsonSchemaForm::Type::Null
      
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
        )
      end

    end
  end
end