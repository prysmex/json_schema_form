module JsonSchemaForm
  module Field
    class Slider < ::JsonSchemaForm::Type::Number
      
      attribute :displayProperties, {
        type: Types::Hash.schema(
          i18n: Types::Hash.schema(
            label: Types::Hash.schema(
              es: Types::String.optional,
              en: Types::String.optional
            ).strict,
            enum: Types::Hash.schema(
              es: Types::Hash.optional,
              en: Types::Hash.optional
            ).strict
          ).strict,
          visibility: Types::Hash.schema(
            label: Types::Bool
          ),
          sort: Types::Integer,
          hidden: Types::Bool,
          useSlider: Types::Bool
        ).strict
      }

    end
  end
end