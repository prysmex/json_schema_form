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
          is_inspection = passthru[:is_inspection]

          Dry::Schema.define(parent: super) do
            optional(:default).value(:bool)
            required(:displayProperties).hash do
              optional(:hidden).filled(:bool)
              optional(:hideOnCreate).filled(:bool)
              required(:i18n).hash do
                required(:falseLabel).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
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
              end
              required(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:useToggle).filled(:bool)
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            optional(:extra).value(:array?).array(:str?).each(included_in?: ['reports', 'notes', 'pictures']) if is_inspection
            required(:type)
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

        # get the translation for a value
        #
        # @param [] value
        # @param [String,Symbol] locale
        # @return [String]
        def i18n_value(value, locale = DEFAULT_LOCALE)
          label_key = if value == true
            :trueLabel
          elsif value == false
            :falseLabel
          end
          self.dig(:displayProperties, :i18n, label_key, locale)
        end
  
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

        # Returns true if field contributes to scoring
        #
        # @override
        #
        # @return [Boolean]
        def scored?
          true
        end
  
      end
    end
  end
end