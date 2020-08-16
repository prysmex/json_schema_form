module JsonSchemaForm
  module Field

    module ResponseSettable
      # get the translation for a value in the field's response set
      def i18n_value(value, locale = :es)
        self
          .response_set
          .get_response_from_value(value)
          &.dig(:displayProperties, :i18n, locale)
      end

      #get the field's response set, only applies to certain fields
      def response_set
        root_form.get_response_set(self[:responseSetId])
      end
    end

    module InstanceMethods

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

      #get the field's localized label
      def i18n_label(locale = :es)
        self.dig(:displayProperties, :i18n, :label, locale)
      end

    end
  end
end