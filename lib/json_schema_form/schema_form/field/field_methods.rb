module SchemaForm
  module Field

    module Base

      def self.included(base)
        base.include JsonSchema::SchemaMethods::Schemable
        base.include JsonSchema::Validations::Validatable
        base.include SchemaForm::Field::BaseMethods
        # base.include JsonSchema::SchemaMethods::Buildable
      end

    end

    module BaseMethods

      def self.included(base)
        require 'dry-schema'
      end
      
      #get the field's localized label
      def i18n_label(locale = :es)
        self.dig(:displayProperties, :i18n, :label, locale)
      end
      
      def valid_for_locale?(locale = :es)
        case self
        when SchemaForm::Field::Static
          true
        else
          i18n_label(locale).to_s.empty?
        end
      end

      def validation_schema
        Dry::Schema.JSON do
          config.validate_keys = true
          required(:'$id').filled(:string)
          optional(:title).filled(:string)
          optional(:'$schema').filled(:string)
        end
      end

      def own_errors
        errors_hash = JsonSchema::Validations::DrySchemaValidatable::OWN_ERRORS_PROC.call(validation_schema, self)
        
        if !SchemaForm::Form::CONDITIONAL_FIELDS.include?(self.class) && self.dependent_conditions.size > 0
          errors_hash[:conditionals] = "only the following fields can have conditionals (#{SchemaForm::Form::CONDITIONAL_FIELDS.map{|k| k.name.demodulize}.join(', ')})"
        end
        
        errors_hash
      end

      # do nothing, field errors are not recursive
      # due to business logic, it is simpler to consider that a field is the last leaf of a schema branch
      def add_subschema_errors(errors)
      end

      def compile!
        self.delete(:displayProperties)
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
        case self
        when Checkbox
          root_parent&.get_response_set(self.dig(:items, :$ref))
        when Select
          root_parent&.get_response_set(self[:$ref])
        end
      end

      def own_errors
        errors_hash = super
        
        if self.response_set.nil?
          errors_hash[:responseSet] = 'response set is not present'
        end
        
        errors_hash
      end

    end

  end
end