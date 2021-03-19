module JsonSchemaForm
  module Validations
    module Validatable

      HASH_SUBSCHEMA_KEYS = [
        :properties, :if, :then, :else, :additionalProperties, :dependencies, :patternProperties,
        :contains,
        :not,
        :definitions,
        :items
      ].freeze

      ARRAY_SUBSCHEMA_KEYS = [
        :allOf,
        :anyOf,
        :oneOf,
        :items
      ].freeze

      BURY_ERRORS_PROC = Proc.new do |errors_to_bury, errors_hash, obj_path|
        errors_to_bury.flatten_to_root.each do |relative_path, errors_array|
          path = (obj_path || []) + (relative_path.to_s.split('.')).map{|i| Integer(i) rescue i.to_sym }
          errors_hash.bury(*(path + [errors_array]))
        end
      end

      #override to implement schema errors
      def own_errors
        raise StandardError.new("need to override 'own_errors' method")
      end

      def add_subschema_errors(errors)
        #continue recurrsion for all subschema keys
        self.each do |key, value|
          begin
            if key == :properties
              self[:properties]&.each do |k,v|
                v.errors(errors)
              end
            elsif key == :definitions
              self[:definitions]&.each do |k,v|
                v.errors(errors)
              end
            elsif key == :additionalProperties
              next if !value.is_a?(::Hash)
              self[:additionalProperties]&.each do |k,v|
                v.errors(errors)
              end
            else
              case value
              when ::Array
                next if !ARRAY_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
                value.each do |v|
                  v.errors(errors)
                end
              else
                next if !HASH_SUBSCHEMA_KEYS.include?(key) # assume it is a Schema
                value.errors(errors)
              end
            end
          rescue => exception
            debugger
          end
        end
      end
      
      # recursively get errors
      def errors(errors={})
        
        # check for errors and set them on the passed errors hash
        own_errors = self.own_errors
        BURY_ERRORS_PROC.call(own_errors, errors, self.meta[:path])

        # go recursive
        self.add_subschema_errors(errors)

        errors
      end

    end
  end
end