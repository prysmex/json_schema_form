module JsonSchemaForm
  module Field
    class Slider < ::JsonSchemaForm::JsonSchema::Number

      include ::JsonSchemaForm::Field::InstanceMethods

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          # required(:responseSetId) { int? | str? }
          required(:displayProperties).hash do
            required(:pictures).value(:array?).array(:str?)
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

      ##################
      #####METHODS######
      ##################

      def max_score
        self[:enum]&.max
      end

      def score_for_value(value)
        value
      end

      def migrate!
      end

      def valid_for_locale?(locale = :es)
        label_is_valid = super

        any_translation_missing = self[:enum].find do |value|
          self.dig(:displayProperties, :i18n, :enum, locale).nil?
        end.present?
        
        label_is_valid && !any_translation_missing
      end

    end
  end
end