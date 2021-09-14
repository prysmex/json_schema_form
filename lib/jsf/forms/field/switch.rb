module JSF
  module Forms
    module Field
      class Switch < BaseHash

        include ::JSF::Forms::Field::Methods::Base
        include JSF::Core::Type::Booleanable
  
        set_strict_type('boolean')
  
        ##################
        ###VALIDATIONS####
        ##################
  
        def validation_schema(passthru)
          Dry::Schema.define(parent: super) do
            required(:type)
            optional(:default).value(:bool)
            required(:displayProperties).hash do
              optional(:hideOnCreate).filled(:bool)
              required(:pictures).value(:array?).array(:str?)
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
                required(:trueLabel).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
                required(:falseLabel).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
              required(:sort).filled(:integer)
              optional(:hidden).filled(:bool)
              required(:useToggle).filled(:bool)
            end
          end
        end

        # @param [String, Symbol] locale
        # @return [Boolean]
        def valid_for_locale?(locale = DEFAULT_LOCALE)
          super &&
            !self.dig(:displayProperties, :i18n, :trueLabel, locale).to_s.empty? &&
            !self.dig(:displayProperties, :i18n, :falseLabel, locale).to_s.empty?
        end
  
        ##################
        #####METHODS######
        ##################
  
        # @return [1]
        def max_score
          1
        end
  
        # Returns a score for a value
        #
        # @param [Boolean, Nilclass]
        # @return [1,0,nil]
        def score_for_value(value)
          case value
          when true
            1
          when false
            0
          when nil
            nil
          else
            raise TypeError.new("value must be boolean or nil, got: #{value.class}")
          end
        end

        def migrate!
        end
  
      end
    end
  end
end