module JsonSchemaForm
  module Field

    module Base

      def self.included(base)
        base.include JsonSchemaForm::JsonSchema::Schemable
        base.include JsonSchemaForm::JsonSchema::Validatable
      end
      
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

      def schema_instance_errors
        errors_hash = super
        
        if !CONDITIONAL_FIELDS.include?(self.class) && self.dependent_conditions.size > 0
          errors_hash[:conditionals] = "only the following fields can have conditionals (#{CONDITIONAL_FIELDS.map{|k| k.name.demodulize}.join(', ')})"
        end
        
        errors_hash
      end

    end

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

      def schema_instance_errors
        errors_hash = super
        
        if self[:responseSetId].nil?
          errors_hash[:responseSetId] = 'must be present'
        elsif self.response_set.nil?
          errors_hash[:responseSetId] = 'response set is not present'
        end
        errors_hash
      end

    end

  end
end