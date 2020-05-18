module JsonSchemaForm
  module Type
    class Null < Base

      attribute :type, {
        type: Types::String.enum('null')
      }

    end
  end
end