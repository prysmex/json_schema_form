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
      
      def validation_schema(is_inspection)
        # is_inspection = self.meta[:is_inspection]
        Dry::Schema.JSON do
          config.validate_keys = true
          required(:id).filled(:integer)
          required(:responses).array(:hash) do
            required(:value).value(:string)
            if is_inspection
              required(:score).value(:integer)
              required(:failed).value(:bool)
            end
            required(:displayProperties).hash do
              required(:i18n).hash do
                optional(:es).maybe(:string)
                optional(:en).maybe(:string)
                if is_inspection
                  required(:color).value(:string)
                end
              end
            end
          end
        end
      end

    end
  end
end