module JsonSchemaForm
  class InspectionForm < ::JsonSchemaForm::Form

    def validation_schema
      Dry::Schema.define(parent: super) do
        config.validate_keys = true
        optional(:maxScore).maybe(:integer)
      end
    end

  end
end