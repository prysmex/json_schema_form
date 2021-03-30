module SchemaForm
  module Field

    module Base

      def self.included(base)
        base.include JsonSchema::SchemaMethods::Schemable
        base.include JsonSchema::Validations::Validatable
        base.include SchemaForm::Field::BaseMethods
        # base.include SuperHash::Helpers
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

      def set_label_for_locale(label, locale = :es)
        SuperHash::Utils.bury(self, :displayProperties, :i18n, :label, locale, label)
      end
      
      def valid_for_locale?(locale = :es)
        !i18n_label(locale).to_s.empty?
      end

      def own_errors(passthru)
        JsonSchema::Validations::DrySchemaValidatable::OWN_ERRORS_PROC.call(
          validation_schema(passthru),
          self
        )
      end

      def validation_schema(passthru)
        Dry::Schema.JSON do
          config.validate_keys = true
          optional(:$id).filled(:string)
          optional(:title).filled(:string)
          optional(:'$schema').filled(:string)
        end
      end

      def compile!
        self.delete(:displayProperties)
      end

    end

    module ResponseSettable

      REF_REGEX = /\A#\/definitions\/[a-z0-9\-_]+\z/

      # get the translation for a value in the field's response set
      def i18n_value(value, locale = :es)
        self
          .response_set
          .get_response_from_value(value)
          &.dig(:displayProperties, :i18n, locale)
      end

      def response_set_id
        self[:$ref]
      end

      #get the field's response set, only applies to certain fields
      def response_set
        path = self.response_set_id&.sub('#/', '')&.split('/')&.map(&:to_sym)
        root_parent&.dig(*path) unless path.nil? || path.empty?
      end

      def own_errors(passthru)
        errors = super
        errors['$ref_path'] = "$ref must match this regex #{REF_REGEX}" if self.response_set_id&.match(REF_REGEX).nil?
        errors
      end

    end

  end
end