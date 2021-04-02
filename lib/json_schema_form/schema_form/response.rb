module SchemaForm
  class Response < ::SuperHash::Hasher

    include JsonSchema::SchemaMethods::Schemable

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
              optional(locale).maybe(:string)
            end
          end
          optional(:color).maybe(:string)
        end
        if is_inspection
          required(:enableScore).value(Types::True)
          required(:score) { int? | float? | nil? }
          required(:failed).value(:bool)
        end
      end
    end

    def errors(passthru={}, errors={})
      own_errors = JsonSchema::Validations::DrySchemaValidatable::OWN_ERRORS_PROC.call(
        validation_schema(passthru),
        self
      )
      JsonSchema::Validations::Validatable::BURY_ERRORS_PROC.call(own_errors, errors, self.meta[:path])
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