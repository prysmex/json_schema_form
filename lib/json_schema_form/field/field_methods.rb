module JsonSchemaForm
  module Field
    module FieldMethods

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

      #get the field's response set, only applies to certain fields
      def response_set
        klass_whitelist = [
          ::JsonSchemaForm::Field::Select,
          ::JsonSchemaForm::Field::Checkbox
        ]
        if klass_whitelist.include?(self.class )
          root_form.get_response_set(self[:responseSetId])
        else
          raise NoMethodError.new("undefined method `response_set' for #{self.class}")
        end
      end

      #get the field's localized label
      def i18n_label(locale = :es)
        self.dig(:displayProperties, :i18n, :label, locale)
      end

    end
  end
end