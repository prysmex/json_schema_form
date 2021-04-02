module SchemaForm
  module Field
    class Switch < ::SuperHash::Hasher

      include ::SchemaForm::Field::Base
      include JsonSchema::StrictTypes::Boolean

      ##################
      ###VALIDATIONS####
      ##################

      def validation_schema(passthru)
        Dry::Schema.define(parent: super) do
          required(:type)
          optional(:default).value(:bool)
          required(:displayProperties).hash do
            optional(:hiddenOnCreate).maybe(:bool)
            required(:pictures).value(:array?).array(:str?)
            required(:i18n).hash do
              required(:label).hash do
                AVAILABLE_LOCALES.each do |locale|
                  optional(locale).maybe(:string)
                end
              end
              required(:trueLabel).hash do
                AVAILABLE_LOCALES.each do |locale|
                  optional(locale).maybe(:string)
                end
              end
              required(:falseLabel).hash do
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
            required(:useToggle).filled(:bool)
          end
        end
      end

      ##################
      #####METHODS######
      ##################

      def max_score
        1
      end

      def score_for_value(value)
        case value
        when true
          1
        when false
          0
        else
          nil
        end
      end

      def migrate!
      end

      def valid_for_locale?(locale = DEFAULT_LOCALE)
        super &&
          !self.dig(:displayProperties, :i18n, :trueLabel, locale).to_s.empty? &&
          !self.dig(:displayProperties, :i18n, :falseLabel, locale).to_s.empty?
      end

    end
  end
end