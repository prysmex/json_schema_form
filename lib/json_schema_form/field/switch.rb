module JsonSchemaForm
  module Field
    class Switch < ::JsonSchemaForm::Type::Boolean
      
      attribute :displayProperties, {
        type: Types::Hash.schema(
          i18n: Types::Hash.schema(
            label: Types::Hash.schema(
              es: Types::String.optional,
              en: Types::String.optional
            ).strict,
            trueLabel: Types::Hash.schema(
              es: Types::String.optional,
              en: Types::String.optional
            ).strict,
            falseLabel: Types::Hash.schema(
              es: Types::String.optional,
              en: Types::String.optional
            ).strict,
          ).strict,
          visibility: Types::Hash.schema(
            label: Types::Bool
          ),
          sort: Types::Integer,
          hidden: Types::Bool,
          useToggle: Types::True
        ).strict
      }

    end
  end
end