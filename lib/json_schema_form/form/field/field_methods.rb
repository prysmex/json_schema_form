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
        root_parent.get_response_set(self[:responseSetId])
      end
    end

    module InstanceMethods

      #get the field's localized label
      def i18n_label(locale = :es)
        self.dig(:displayProperties, :i18n, :label, locale)
      end
      
      def valid_for_locale?(locale = :es)
        case self
        when JsonSchemaForm::Field::Static
          true
        else
          i18n_label(locale).present?
        end
      end

    end
  end
end