module JSF
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

    def own_errors(passthru)
      {}
    end

  end
end