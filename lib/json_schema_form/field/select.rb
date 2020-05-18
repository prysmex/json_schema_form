module JsonSchemaForm
  module Field
    class Select < ::JsonSchemaForm::Type::String
      
      attribute :displayProperties, {
        type: Types::Hash.schema(
          i18n: Types::Hash.schema(
            label: Types::Hash.schema(
              es: Types::String,
              en: Types::String
            ).strict,
            enum: Types::Hash.schema(
              es: Types::Hash,
              en: Types::Hash
            ).strict
          ).strict,
          visibility: Types::Hash.schema(
            label: Types::Bool
          ),
          sort: Types::Integer,
          hidden: Types::Bool
        ).strict
      }

    end
  end
end