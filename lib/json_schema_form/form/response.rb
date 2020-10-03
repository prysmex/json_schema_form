module JsonSchemaForm
  class Response < ::SuperHash::Hasher

    instance_variable_set('@allow_dynamic_attributes', true)
    attr_reader :meta

    def initialize(obj, meta={}, options={}, &block)
      @meta = meta
      super(obj, options, &block)
    end

    ##################
    ###VALIDATIONS####
    ##################
    
    def validation_schema
      is_inspection = self.meta[:parent].meta[:parent].is_inspection
      Dry::Schema.JSON do
        config.validate_keys = true
        required(:value).value(:string)
        if is_inspection
          required(:enableScore).value(Types::True)
          required(:score) { int? | float? | nil? }
          required(:failed).value(:bool)
        end
        required(:displayProperties).hash do
          required(:i18n).hash do
            optional(:es).maybe(:string)
            optional(:en).maybe(:string)
          end
          if is_inspection
            required(:color).maybe(:string)
          end
        end
      end
    end

    def schema_validation_hash
      Marshal.load(Marshal.dump(self))# new reference
    end

    def valid_with_schema?
      schema_errors.empty?
    end

    def schema_errors
      validation_schema.(schema_validation_hash).errors.to_h.merge({})
    end

    ##############
    ###METHODS####
    ##############

    def valid_for_locale?(locale = :es)
      self.dig(:displayProperties, :i18n, locale).present?
    end

  end
end