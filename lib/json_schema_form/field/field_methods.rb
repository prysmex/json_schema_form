module JsonSchemaForm
  module Field
    module FieldMethods
      def label(locale = :es)
        self.dig(:displayProperties, :i18n, :label, locale)
      end
    end
  end
end