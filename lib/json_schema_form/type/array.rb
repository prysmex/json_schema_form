module JsonSchemaForm
  module Type
    class Array < Base

      ITEMS_PROC = ->(instance, value) {
        if value.is_a?(::Array)
          value.map{|i| BUILDER.call(i, {parent: instance}) }
        elsif value.is_a?(::Hash)
          BUILDER.call(value, {parent: instance})
        else
          raise StandardError.new('invalid items')
        end
      }

      CONTAINS_PROC = ->(instance, value) {
        BUILDER.call(value, {parent: instance}) if value.present?
      }

      attribute :type, {
        type: Types::String.enum('array')
      }
      attribute? :items, {
        # type: (Types::Array | Types::Hash),
        transform: ITEMS_PROC
      }
      attribute? :contains, {
        # type: (Types::Array | Types::Hash),
        transform: CONTAINS_PROC
      }

      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:type).filled(:string).value(included_in?: ['array'])
          optional(:items)# todo value type
          optional(:contains)# todo value type
          optional(:additionalItems) { bool? | hash? }
          optional(:minItems).filled(:integer)
          optional(:maxItems).filled(:integer)
          optional(:uniqueItems).filled(:bool)
        end
      end

      def validations
        super.merge({
          items: self&.[](:items)&.validations,
          contains: self&.[](:contains)&.validations,
          additionalItems: self[:additionalItems],
          minItems: self[:minItems],
          maxItems: self[:maxItems],
          uniqueItems: self[:uniqueItems],
          required: self.required?
        }).compact
      end

      private

    end
  end
end