module JsonSchemaForm
  module Type
    class Array < Base

      ITEMS_PROC = ->(instance, value) {
        if value.is_a?(::Array)
          value.map{|i| Builder.build_schema(i, instance) }
        elsif value.is_a?(::Hash)
          Builder.build_schema(value, instance)
        else
          raise StandardError.new('invalid items')
        end
      }

      CONTAINS_PROC = ->(instance, value) {
        Builder.build_schema(value, instance) if value.present?
      }

      attribute? :items, {
        type: (Types::Array | Types::Hash),
        transform: ITEMS_PROC
      }
      attribute? :contains, {
        type: (Types::Array | Types::Hash),
        transform: CONTAINS_PROC
      }
      attribute? :additionalItems, {
        type: (Types::Bool | Types::Hash)
      }
      attribute? :minItems, {
        type: Types::Integer
      }
      attribute? :maxItems, {
        type: Types::Integer
      }
      attribute? :uniqueItems, type: Types::Bool.optional

      def validations
        super.merge({
          items: self[:items].try(:validations),
          contains: self[:contains].try(:validations),
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