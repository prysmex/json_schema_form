module JsonSchema
  class Schema < SchemaHash
    
    include JsonSchema::SchemaMethods::Schemable
    include JsonSchema::SchemaMethods::Buildable
    include JsonSchema::SchemaMethods::Objectable
    include JsonSchema::SchemaMethods::Stringable
    include JsonSchema::SchemaMethods::Numberable
    include JsonSchema::SchemaMethods::Booleanable
    include JsonSchema::SchemaMethods::Arrayable
    include JsonSchema::SchemaMethods::Nullable
    include JsonSchema::Validations::Validatable

    def own_errors(passthru)
      {}
    end

  end
end