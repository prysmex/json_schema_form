module SchemaForm
  module Field
    class Header < SchemaHash

      include ::SchemaForm::Field::Base
      include JsonSchema::StrictTypes::Null

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema(passthru)
        Dry::Schema.define(parent: super) do
          required(:type)
          required(:displayProperties).hash do
            optional(:hideOnCreate).maybe(:bool)
            required(:pictures).value(:array?).array(:str?)
            required(:i18n).hash do
              required(:label).hash do
                AVAILABLE_LOCALES.each do |locale|
                  optional(locale).maybe(:string)
                end
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