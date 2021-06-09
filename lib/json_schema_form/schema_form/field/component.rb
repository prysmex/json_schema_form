module SchemaForm
  module Field
    class Component < ::SuperHash::Hasher

      include ::SchemaForm::Field::Base
  
      REF_REGEX = /\A#\/definitions\/\w+\z/
  
      def validation_schema(passthru)
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:$ref).filled(:string)
          required(:displayProperties).hash do
            optional(:hideOnCreate).maybe(:bool)
            required(:i18n).hash do
              required(:label).hash do
                AVAILABLE_LOCALES.each do |locale|
                  optional(locale).maybe(:string)
                end
              end
            end
            required(:visibility).hash do
              required(:label).filled(:bool)
            end
            required(:sort).filled(:integer)
            required(:hidden).filled(:bool)
          end
        end
      end
  
      def own_errors(passthru)
        errors = super
        errors['$ref_path'] = "$ref must match this regex #{REF_REGEX}" if self[:$ref]&.match(REF_REGEX).nil?
        errors
      end

      def component_definition_id
        self.dig(*[:$ref])
      end

      def component_definition_id=(id)
        SuperHash::Utils.bury(self, *[:$ref], "#/definitions/#{id}")
      end

      #get the field's response set, only applies to certain fields
      def component_definition
        path = self.component_definition_id&.sub('#/', '')&.split('/')&.map(&:to_sym)
        return if path.nil? || path.empty?
        find_parent do |current, _next|
          current.key?(:definitions)
        end&.dig(*path)
      end
  
    end
  end
end