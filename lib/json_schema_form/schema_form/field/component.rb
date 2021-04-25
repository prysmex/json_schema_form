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
  
    end
  end
end