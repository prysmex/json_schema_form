module JsonSchemaForm
  module Type
    class String < Base

      attribute :type, {
        type: Types::String.enum('string')
      }
      attribute? :minLength
      attribute? :maxLength
      attribute? :pattern
      attribute? :format
      attribute? :enum, {
        type: Types::Array.optional#.of(Types::String)
      }

      def validations
        super.merge({
          minLength: self[:minLength],
          maxLength: self[:maxLength],
          pattern: self[:pattern],
          format: self[:format],
          enum: self[:enum]
        }).compact
      end

    end
  end
end