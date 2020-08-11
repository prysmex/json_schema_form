module JsonSchemaForm
  module Field
    class ResponseSet < ::SuperHash::Hasher

      instance_variable_set('@allow_dynamic_attributes', true)
      attr_reader :meta

      def initialize(obj, meta={}, &block)
        @meta = meta
        super(obj, &block)
      end

      # FORM_RESPONSE_PROC = ->(instance, value) {
      #   value&.each do |id, obj|
      #     path = if instance&.meta&.dig(:path)
      #       instance.meta[:path].concat([:responseSets, id])
      #     else
      #      [:responseSets, id]
      #     end
      #     value[id] = JsonSchemaForm::Field::ResponseSet.new(obj, {
      #       parent: instance,
      #       path: path
      #     })
      #   end
      # }

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema
        is_inspection = self.meta[:parent].is_inspection
        Dry::Schema.JSON do
          config.validate_keys = true
          required(:id) { int? | str? }
          required(:responses).array(:hash) do
            required(:value).value(:string)
            if is_inspection
              required(:enableScore).value(Types::True)
              required(:score).maybe(:integer)
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

      ##############
      ###METHODS####
      ##############

      # def add_response
      # end

      # def remove_response
      # end

      def get_response_from_value(value)
        self[:responses].find{|r| r[:value] == value }
      end

      # def get_failing_responses
      # end

      # def get_passing_responses
      # end

    end
  end
end