module JSF
  module Forms
    class Response < BaseHash
  
      include JSF::Core::Schemable
      include JSF::Validations::Validatable
  
      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema(passthru)
        is_inspection = passthru[:is_inspection]
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
          end
          if is_inspection
            required(:enableScore).value(Types::True)
            required(:score) { nil? | ( (int? | float?) > gteq?(0) ) }
            required(:failed).value(:bool)
          end
        end
      end
  
      def own_errors(passthru)
        JSF::Validations::DrySchemaValidatable::SCHEMA_ERRORS_PROC.call(
          validation_schema(passthru),
          self
        )
      end
  
      ##############
      ###METHODS####
      ##############
  
      def set_translation(label, locale = DEFAULT_LOCALE)
        SuperHash::Utils.bury(self, :displayProperties, :i18n, locale, label)
      end
  
      def valid_for_locale?(locale = DEFAULT_LOCALE)
        !self.dig(:displayProperties, :i18n, locale).to_s.empty?
      end
  
    end
  end
end
