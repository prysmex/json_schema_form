module JsonSchemaForm
  module Field
    class Static < ::JsonSchemaForm::Type::Null
      
      attribute :static, type: Types::True
      attribute :displayProperties, {
        type: Types::Hash.schema(
          sort: Types::Integer,
          hidden?: Types::Bool
        ).strict
      }

    end
  end
end