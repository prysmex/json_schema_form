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

      def has_dependent_conditions?
        dependent_conditions.length > 0
      end

      def dependent_conditions
        self.meta[:parent][:allOf].select do |condition|
          condition.dig(:if, :properties).keys.include?(self.key_name.to_sym)
        end
      end

      def dependent_conditions_for_value(value)
        dependent_conditions.select do |condition|
          negated = !condition.dig(:if, :properties, self.key_name.to_sym, :not).nil?
          condition_type = if negated
            condition.dig(:if, :properties, self.key_name.to_sym, :not)
          else
            condition.dig(:if, :properties, self.key_name.to_sym)
          end

          match = case condition_type.keys[0]
          when :const
            condition_type[:const] == value
          when :enum
            condition_type[:enum].include?(value)
          end
          negated ? !match : match
        end
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