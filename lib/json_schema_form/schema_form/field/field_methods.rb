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

      def hidden?
        self.dig(:displayProperties, :hidden)
      end

      def hideOnCreate?
        self.dig(:displayProperties, :hideOnCreate)
      end

      def hidden=(value)
        SuperHash::Utils.bury(self, :displayProperties, :hidden, value)
      end
      
      #get the field's localized label
      def i18n_label(locale = DEFAULT_LOCALE)
        self.dig(:displayProperties, :i18n, :label, locale)
      end

      def set_label_for_locale(label, locale = DEFAULT_LOCALE)
        SuperHash::Utils.bury(self, :displayProperties, :i18n, :label, locale, label)
      end
      
      def valid_for_locale?(locale = DEFAULT_LOCALE)
        !i18n_label(locale).to_s.empty?
      end

      def own_errors(passthru)
        JsonSchema::Validations::DrySchemaValidatable::OWN_ERRORS_PROC.call(
          validation_schema(passthru),
          self
        )
      end

      # {
      #   definitions: {
      #     shared_schema_template_2: {
      #       properties: {
      #         migrated_hazards9999: {}
      #       },
      #       allOf: [
      #         {
      #           then: {
      #             properties: {
      #               other_hazards_9999: {}
      #             }
      #           }
      #         }
      #       ]
      #     }
      #   },
      #   properties: {
      #     shared_schema_template_2_9999: { ref: :shared_schema_template_2}
      #   }
      # }
      def document_path
        path = self.meta[:path]
        new_path = []

        is_shared_schema_template_field = path[0] == :definitions

        if is_shared_schema_template_field
          root_form = self.root_parent
          field = nil
          root_form.schema_form_iterator(skip_when_false: true) do |_, form|
            field = form.properties.find do |key, prop|
              next unless prop.is_a?(SchemaForm::Field::Component)
              prop.component_definition == root_form.dig(*path.slice(0..1))
            end
            field = field[1] if field
            !field
          end
          new_path.push(field.key_name)
        end

        new_path.push(self.key_name)
        new_path
      end

      def validation_schema(passthru)
        Dry::Schema.JSON do
          config.validate_keys = true
          optional(:$id).filled(:string)
          optional(:title).maybe(:string)
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
      def i18n_value(value, locale = DEFAULT_LOCALE)
        self
          .response_set
          .get_response_from_value(value)
          &.dig(:displayProperties, :i18n, locale)
      end

      def response_set_id
        self.dig(*self.class::RESPONSE_SET_PATH)
      end

      def response_set_id=(id)
        SuperHash::Utils.bury(self, *self.class::RESPONSE_SET_PATH, "#/definitions/#{id}")
      end

      #get the field's response set, only applies to certain fields
      def response_set
        path = self.response_set_id&.sub('#/', '')&.split('/')&.map(&:to_sym)
        return if path.nil? || path.empty?
        find_parent do |current, _next|
          current.key?(:definitions)
        end&.dig(*path)
      end

      def own_errors(passthru)
        errors = super
        errors['$ref_path'] = "$ref must match this regex #{REF_REGEX}" if self.response_set_id&.match(REF_REGEX).nil?
        errors
      end

    end

  end
end