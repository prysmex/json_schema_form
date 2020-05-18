module JsonSchemaForm
  module Type
    class Boolean < Base

      attribute :type, {
        type: Types::String.enum('boolean')
      }

    end
  end
end