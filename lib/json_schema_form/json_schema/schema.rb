require 'super_hash'
require 'dry-schema'

module JsonSchemaForm
  module JsonSchema

    class Schema < ::SuperHash::Hasher
      
      include JsonSchemaForm::JsonSchema::Schemable
      include JsonSchemaForm::JsonSchema::Validatable
      include JsonSchemaForm::JsonSchema::Attributes
      include JsonSchemaForm::JsonSchema::Objectable
      include JsonSchemaForm::JsonSchema::Stringable
      include JsonSchemaForm::JsonSchema::Numberable
      include JsonSchemaForm::JsonSchema::Booleanable
      include JsonSchemaForm::JsonSchema::Arrayable
      include JsonSchemaForm::JsonSchema::Nullable

    end
  end
end