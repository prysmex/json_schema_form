module JsonSchemaForm
  module Type
    class Number < Base

      attribute? :multipleOf
      attribute? :minimum
      attribute? :maximum
      attribute? :exclusiveMinimum
      attribute? :exclusiveMaximum
      attribute? :enum

      def validations
        super.merge({
          multipleOf: self[:multiple_of],
          minimum: self[:minimum],
          maximum: self[:maximum],
          exclusiveMinimum: self[:exclusive_minimum],
          exclusiveMaximum: self[:exclusive_maximum],
          enum: self[:enum]
        }).compact
      end

    end
  end
end