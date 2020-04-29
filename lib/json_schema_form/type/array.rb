module JsonSchemaForm
  module Type
    class Array < Base

      # property :items, transform_with: Proc.new { |value|
      #   if value.is_a?(::Array)
      #     value.map{|i| Builder.build_schema(i, self) }
      #   elsif value.is_a?(::Hash)
      #     Builder.build_schema(value, self)
      #   else
      #     raise StandardError.new('invalid items')
      #   end
      # }
      # property :contains, transform_with: Proc.new { |value|
      #   Builder.build_schema(value, self) if value.present?
      # }
      # property :additional_items
      # property :min_items
      # property :max_items
      # property :unique_items

      # def validations
      #   super.merge({
      #     items: items.try(:validations),
      #     contains: contains.try(:validations),
      #     additionalItems: additional_items,
      #     minItems: min_items,
      #     maxItems: max_items,
      #     uniqueItems: unique_items,
      #     required: _required?
      #   }).compact
      # end

      private

    end
  end
end