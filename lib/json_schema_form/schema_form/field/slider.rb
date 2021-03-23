module SchemaForm
  module Field
    class Slider < ::SuperHash::Hasher

      include ::SchemaForm::Field::Base
      include JsonSchema::StrictTypes::Number

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema
        Dry::Schema.define(parent: super) do

          before(:key_validator) do |result|
            hash = result.to_h.inject({}) do |acum, (k,v)|
              acum[k] = v
              acum
            end
            enum_locales = hash.dig(:displayProperties, :i18n, :enum)
            enum_locales&.each do |lang, locales|
              locales&.clear
            end
            hash
          end

          required(:type)
          required(:enum).array{ int? | float? }
          required(:displayProperties).hash do
            optional(:hiddenOnCreate).maybe(:bool)
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

      def valid_for_locale?(locale = :es)
        label_is_valid = super

        any_translation_missing = !!self[:enum].find do |value|
          self.dig(:displayProperties, :i18n, :enum, locale, value).nil?
        end
        
        label_is_valid && !any_translation_missing
      end

    end
  end
end