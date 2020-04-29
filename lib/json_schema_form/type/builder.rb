module JsonSchemaForm
  module Type
    class Builder

      def self.build_schema(obj, parent=nil)
        type = obj[:type]
        case type
        when 'string', :string
          JsonSchemaForm::Type::String.new(obj, parent)
        when 'number', :number, 'integer', :integer
          JsonSchemaForm::Type::Number.new(obj, parent)
        when 'boolean', :boolean
          JsonSchemaForm::Type::Boolean.new(obj, parent)
        when 'array', :array
          JsonSchemaForm::Type::Array.new(obj, parent)
        when 'object', :object
          JsonSchemaForm::Type::Object.new(obj, parent)
        when 'null', :null
          JsonSchemaForm::Type::Null.new(obj, parent)
        else
          raise StandardError.new('schema type is not valid')
        end        
      end

    end
  end
end