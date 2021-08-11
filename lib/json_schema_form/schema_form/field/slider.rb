module SchemaForm
  module Field
    class Slider < ::SuperHash::Hasher

      include ::SchemaForm::Field::Base
      include JsonSchema::StrictTypes::Number

      MAX_ENUM_SIZE = 25

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema(passthru)
        Dry::Schema.define(parent: super) do

          before(:key_validator) do |result|
            duplicate = result.to_h.deep_dup
            duplicate.dig(:displayProperties, :i18n, :enum)&.each do |lang, locales|
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

      def own_errors(passthru)
        errors = super

        if self[:enum].is_a?(Array)
          # enum length
          errors['_enum_size_'] = "The max length of enum is #{MAX_ENUM_SIZE}" if self[:enum].length > MAX_ENUM_SIZE
  
          # enum spacing
          if self[:enum].size > 1
            diff = (self[:enum][1] - self[:enum][0]).abs
            self[:enum].each_with_index do |value, i|
              next if i == 0
              new_diff = (self[:enum][i] - self[:enum][i-1]).abs
              if diff != new_diff
                errors['_enum_spacing_'] = "found different spacing from initial at index #{i}"
                break
              end
            end
          end
        end

        errors
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