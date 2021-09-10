module JSF
  #
  # Backing class that can be used as a generic JSON schema. It does not have
  # any context for JSF::Forms classes
  #
  # Some reasons to use this class would be:
  # 
  # - to validate a JSON schema, for default validations, include `JSF::Validations::DrySchemaValidatable`
  # - Indifferent access (symbol and hash)
  #
  class Schema < BaseHash
    
    include JSF::Core::Schemable
    include JSF::Core::Buildable
    include JSF::Core::Type::Objectable
    include JSF::Core::Type::Stringable
    include JSF::Core::Type::Numberable
    include JSF::Core::Type::Booleanable
    include JSF::Core::Type::Arrayable
    include JSF::Core::Type::Nullable
    include JSF::Validations::Validatable

    # override this for validations
    #
    # @param passthru [Hash{Symbol => *}]
    def own_errors(passthru)
      {}
    end

  end
end