require 'super_hash'

module JsonSchemaForm
  module JsonSchema

    class Schema < ::SuperHash::Hasher
      
      include JsonSchemaForm::JsonSchema::Schemable
      include JsonSchemaForm::JsonSchema::Attributes
      include JsonSchemaForm::JsonSchema::Objectable
      include JsonSchemaForm::JsonSchema::Stringable
      include JsonSchemaForm::JsonSchema::Numberable
      include JsonSchemaForm::JsonSchema::Booleanable
      include JsonSchemaForm::JsonSchema::Arrayable
      include JsonSchemaForm::JsonSchema::Nullable
      include JsonSchemaForm::JsonSchema::Validatable #TODO load only if configured
      include JsonSchemaForm::JsonSchema::DrySchemaValidatable #TODO load only if configured

    end
  end
end