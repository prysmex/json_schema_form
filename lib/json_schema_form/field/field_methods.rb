module JsonSchemaForm
  module Field
    module FieldMethods

      def label(locale = :es)
        self.dig(:displayProperties, :i18n, :label, locale)
      end

      # get the uppermost parent
      def root_form
        parent = meta[:parent]
        loop do
          next_parent = parent.meta[:parent]
          break if next_parent.nil?
          parent = next_parent
        end
        parent
      end

      def response_set
        root_form.response_sets.dig(self[:responseSetId])
      end

    end
  end
end