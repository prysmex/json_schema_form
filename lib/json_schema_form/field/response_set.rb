module JsonSchemaForm
  module Field
    class ResponseSet < JsonSchemaForm::SuperHash

      instance_variable_set('@allow_dynamic_attributes', true)
      attr_reader :meta

      def initialize(obj, meta={}, &block)
        @meta = meta
        super(obj, &block)
      end

      def schema_validation_hash
        Marshal.load(Marshal.dump(self))# new reference
      end

      def valid_with_schema?
        schema_errors.empty?
      end

      def schema_errors
        schema = validation_schema
        if schema
          schema.(schema_validation_hash).errors.to_h
        else
          {}
        end
      end
      
      def validation_schema
        Dry::Schema.JSON do
          config.validate_keys = true

          required(:id).filled(:integer)
          optional(:responses).array(:hash) do
            required(:value).value(:string)
            optional(:score).value(:integer)
            optional(:failed).value(:bool)

            required(:displayProperties).hash do
              required(:i18n).hash do
                optional(:es).maybe(:string)
                optional(:en).maybe(:string)
              end
            end

          end
        end
      end

    end
  end
end