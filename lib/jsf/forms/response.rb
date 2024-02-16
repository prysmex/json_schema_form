module JSF
  module Forms

    #
    # Represents a 'single' response in a JSF::Forms::ResponseSet.
    #
    # @example
    #   {
    #     "type": "string",
    #     "const": "value1",
    #     "displayProperties": {
    #       "i18n": {
    #         "en": "Your translated value",
    #       }
    #     }
    #   }
    #
    # If 'is_inspection', it also contains the following keys:
    #
    # - enableScore
    # - score
    # - failed
    #
    class Response < BaseHash
  
      include JSF::Core::Schemable
      include JSF::Validations::Validatable
      include JSF::Validations::DrySchemaValidatable
  
      ##################
      ###VALIDATIONS####
      ##################
      
      def dry_schema(passthru)
        Dry::Schema.JSON do
          config.validate_keys = true
          required(:type).filled(Types::String.enum('string'))
          required(:const).value(:string)
          required(:displayProperties).hash do
            required(:i18n).hash do
              AVAILABLE_LOCALES.each do |locale|
                optional(locale.to_sym).maybe(:string)
              end
            end
            optional(:color).maybe(:string)
            optional(:tags).value(:array?).array(:str?)
          end
          if passthru[:is_inspection]
            required(:enableScore).value(Types::True) #deprecate?
            required(:score) { nil? | ( (int? | float?) > gteq?(0) ) }
            required(:failed).value(:bool)
          end
        end
      end

      # # @param passthru [Hash{Symbol => *}]
      # def errors(**passthru)
      #   super
      # end

      # Checks if locale is valid
      #
      # @param [String, Symbol] locale
      # @return [Boolean]
      def valid_for_locale?(locale = DEFAULT_LOCALE)
        !self.dig(:displayProperties, :i18n, locale).to_s.empty?
      end
  
      ##############
      ###METHODS####
      ##############
  
      # Sets a locale
      #
      # @param [String] label
      # @param [String,Symbol] locale
      # @return [void]
      def set_translation(label, locale = DEFAULT_LOCALE)
        SuperHash::Utils.bury(self, :displayProperties, :i18n, locale, label)
      end

      def legalize!
        self.delete(:displayProperties)
        self.delete(:enableScore)
        self.delete(:failed)
        self.delete(:score)
        self
      end

      # Checks if the response has an assigned score value
      #
      # @return [Boolean]
      def scored?
        !self[:score].nil?
      end
  
    end
  end
end
