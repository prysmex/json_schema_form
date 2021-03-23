module SchemaForm
  module Field
    class Component < ::SuperHash::Hasher

      include ::SchemaForm::Field::Base
  
      REF_REGEX = /\A#\/definitions\/\w+\z/
  
      def validation_schema
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:$ref).filled(:string)
          required(:displayProperties).hash do
            optional(:hiddenOnCreate).maybe(:bool)
            # required(:pictures).value(:array?).array(:str?)
            required(:i18n).hash do
              required(:label).hash do
                optional(:es).maybe(:string)
                optional(:en).maybe(:string)
              end
            end
            # required(:visibility).hash do
            #   required(:label).filled(:bool)
            # end
            required(:sort).filled(:integer)
            required(:hidden).filled(:bool)
          end
        end
      end
  
      def own_errors
        errors = super
        errors['$ref_path'] = "$ref must match this regex #{REF_REGEX}" if self[:$ref].match(REF_REGEX).nil?
        errors
      end
  
    end
  end
end