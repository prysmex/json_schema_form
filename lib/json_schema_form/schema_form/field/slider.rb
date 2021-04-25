module SchemaForm
  module Field
    class Slider < ::SuperHash::Hasher

      include ::SchemaForm::Field::Base
      include JsonSchema::StrictTypes::Number

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema(passthru)
        Dry::Schema.define(parent: super) do

          before(:key_validator) do |result|
            duplicate =result.to_h.deep_dup
            enum_locales = duplicate.dig(:displayProperties, :i18n, :enum)&.each do |lang, locales|
              locales&.clear
            end
            duplicate
          end

          required(:type)
          required(:enum).array{ int? | float? }
          required(:displayProperties).hash do
            optional(:hideOnCreate).maybe(:bool)
            required(:pictures).value(:array?).array(:str?)
            required(:i18n).hash do
              required(:label).hash do
                AVAILABLE_LOCALES.each do |locale|
                  optional(locale).maybe(:string)
                end
              end
              # ToDo create two types of sliders and remove this when only numbers
              required(:enum).hash do
                AVAILABLE_LOCALES.each do |locale|
                  optional(locale).maybe(:hash)
                end
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

      ##################
      #####METHODS######
      ##################

      def max_score
        self[:enum]&.max
      end

      def score_for_value(value)
        case value
        when ::Integer, ::Float
          value
        else
          nil
        end
      end

      def migrate!
      end

      def valid_for_locale?(locale = DEFAULT_LOCALE)
        label_is_valid = super

        missing_locale = self[:enum].find do |value|
          self.dig(:displayProperties, :i18n, :enum, locale, value&.to_s&.to_sym).to_s.empty?
        end
        
        label_is_valid && !missing_locale
      end

    end
  end
end