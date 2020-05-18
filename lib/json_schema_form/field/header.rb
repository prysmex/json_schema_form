module JsonSchemaForm
  module Field
    class Header < ::JsonSchemaForm::Type::Null
      
      attribute :displayProperties, {
        type: Types::Hash.schema(
          i18n: Types::Hash.schema(
            label: Types::Hash.schema(
              es: Types::String,
              en: Types::String
            ).strict
          ).strict,
          visibility: Types::Hash.schema(
            label: Types::Bool
          ),
          sort: Types::Integer,
          hidden: Types::Bool,
          useHeader: Types::Bool,
          level: Types::Integer.constrained(lteq: 2)
        ).strict
      }

    end
  end
end