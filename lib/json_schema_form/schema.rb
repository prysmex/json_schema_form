require 'super_hash'

module JsonSchemaForm
  class Schema < ::SuperHash::Hasher
      
    include JsonSchemaForm::SchemaMethods::Schemable
    include JsonSchemaForm::SchemaMethods::Buildable
    include JsonSchemaForm::SchemaMethods::Objectable
    include JsonSchemaForm::SchemaMethods::Stringable
    include JsonSchemaForm::SchemaMethods::Numberable
    include JsonSchemaForm::SchemaMethods::Booleanable
    include JsonSchemaForm::SchemaMethods::Arrayable
    include JsonSchemaForm::SchemaMethods::Nullable
    include JsonSchemaForm::Validations::Validatable #TODO load only if configured
    include JsonSchemaForm::Validations::DrySchemaValidatable #TODO load only if configured

  end
end