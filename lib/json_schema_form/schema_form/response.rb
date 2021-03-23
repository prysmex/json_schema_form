module SchemaForm
  class Response < ::SuperHash::Hasher

    include JsonSchema::SchemaMethods::Schemable

    ##################
    ###VALIDATIONS####
    ##################
    
    def validation_schema(is_inspection)
      Dry::Schema.JSON do
        config.validate_keys = true
        required(:type).filled(Types::String.enum('string'))
        required(:const).value(:string)
        required(:displayProperties).hash do
          required(:i18n).hash do
            optional(:es).maybe(:string)
            optional(:en).maybe(:string)
          end
          if is_inspection
            required(:color).maybe(:string)
          end
        end
        if is_inspection
          required(:enableScore).value(Types::True)
          required(:score) { int? | float? | nil? }
          required(:failed).value(:bool)
        end
      end
    end

    def errors(is_inspection: false)
      JsonSchema::Validations::DrySchemaValidatable::OWN_ERRORS_PROC.call(
        validation_schema(is_inspection),
        self
      )
    end

    ##############
    ###METHODS####
    ##############

    def valid_for_locale?(locale = :es)
      !self.dig(:displayProperties, :i18n, locale).to_s.empty?
    end

  end
end