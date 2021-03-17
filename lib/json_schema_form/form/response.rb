module JsonSchemaForm
  class Response < ::SuperHash::Hasher

    include JsonSchemaForm::JsonSchema::Schemable

    ##################
    ###VALIDATIONS####
    ##################
    
    def validation_schema
      is_inspection = self.meta[:parent].meta[:parent].is_inspection
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

    def errors
      validation_schema.(self).errors.to_h.merge({})
    end

    ##############
    ###METHODS####
    ##############

    def valid_for_locale?(locale = :es)
      self.dig(:displayProperties, :i18n, locale).present?
    end

  end
end