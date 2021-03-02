module JsonSchemaForm
  class Component < ::SuperHash::Hasher

    include JsonSchemaForm::JsonSchema::Schemable
    include JsonSchemaForm::JsonSchema::Validatable

    def validation_schema
      Dry::Schema.JSON do
        config.validate_keys = true
        required(:$ref).filled(:integer)
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

    def schema_instance_errors
      errors = validation_schema
        &.(self)
        &.errors
        &.to_h
        &.merge({}) || {}
      errors['$ref_path'] = '$ref must match this regex \A#\/definitions\/\w+\z' if self[:$ref].match(/\A#\/definitions\/\w+\z/).nil?
      errors
    end

  end
end