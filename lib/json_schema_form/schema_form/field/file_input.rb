module SchemaForm
  module Field
    class FileInput < SchemaHash

      include ::SchemaForm::Field::Base
      include JsonSchema::StrictTypes::Array

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema(passthru)
        Dry::Schema.define(parent: super) do
          required(:type)
          required(:uniqueItems)
          optional(:maxItems)
          required(:items).hash do
            required(:'type').filled(Types::String.enum('string'))
            required(:format).filled(Types::String.enum('uri'))
          end
          required(:displayProperties).hash do
            optional(:hideOnCreate).maybe(:bool)
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
          end
        end
      end

      ##################
      #####METHODS######
      ##################

      def migrate!
      end

    end
  end
end