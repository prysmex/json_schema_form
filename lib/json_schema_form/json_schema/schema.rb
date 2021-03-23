require 'super_hash'

module JsonSchema
  class Schema < ::SuperHash::Hasher
    
    include JsonSchema::SchemaMethods::Schemable
    include JsonSchema::SchemaMethods::Buildable
    include JsonSchema::SchemaMethods::Objectable
    include JsonSchema::SchemaMethods::Stringable
    include JsonSchema::SchemaMethods::Numberable
    include JsonSchema::SchemaMethods::Booleanable
    include JsonSchema::SchemaMethods::Arrayable
    include JsonSchema::SchemaMethods::Nullable
    include JsonSchema::Validations::Validatable #TODO load only if configured
    include JsonSchema::Validations::DrySchemaValidatable #TODO load only if configured

  end
end