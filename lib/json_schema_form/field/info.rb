module JsonSchemaForm
  module Field
    class Info < ::JsonSchemaForm::Type::Null
      
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
          kind: Types::String,
          useInfo: Types::Bool,
          icon: Types::String,
          sort: Types::Integer,
          hidden: Types::Bool,
        ).strict
      }

    end
  end
end