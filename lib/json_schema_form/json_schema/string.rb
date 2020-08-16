module JsonSchemaForm
  module JsonSchema
    class String < Base

      attribute :type, {
        type: Types::String.enum('string')
      }

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:type).filled(:string).value(included_in?: ['string'])
          optional(:minLength).filled(:integer)
          optional(:maxLength).filled(:integer)
          optional(:pattern).filled(:string)
          optional(:format).filled(:string)
          optional(:enum).array(:str?)
        end
      end

      def validations
        super.merge({
          minLength: self[:minLength],
          maxLength: self[:maxLength],
          pattern: self[:pattern],
          format: self[:format],
          enum: self[:enum]
        }).compact
      end

    end
  end
end