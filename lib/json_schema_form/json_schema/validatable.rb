module JsonSchemaForm
  module JsonSchema
    module Validatable

      TYPES_TO_PREDICATES = Proc.new do |ctx, types|

        map = {
          'boolean' => ['bool?'],
          'object' => ['hash?'],
          'string' => ['str?'],
          'number' => ['float?', 'int?'],
          'null' => ['nil?'],
          'array' => ['array?']
        }
      
        flat_predicate_names = types&.inject([]) do |acum, type|
          mapped_predicate = map[type]
          case mapped_predicate
          when ::Array
            acum + mapped_predicate
          else
            acum + [mapped_predicate]
          end
        end || ['bool?','hash?','str?','float?','int?','nil?','array?']
        
        flat_predicate_names&.each_with_index&.inject(nil) do |acum_predicate, (predicate_name, i)|
          if i == 0
            ctx.send(predicate_name)
          else
            acum_predicate | ctx.send(predicate_name)
          end
        end
      
      end
      
      def validation_schema
        instance = self
        hash_subschema_keys = [
          :properties, :if, :then, :else, :additionalProperties, :dependencies, :patternProperties,
          :contains,
          :not
        ]
        array_subschema_keys = [
          :allOf,
          :anyOf,
          :oneOf,
          :items, 
        ]

        Dry::Schema.JSON do

          config.validate_keys = true

          # need to clear data because jsonschema always tries to validate
          # for unknown keys inside hashes and arrays
          before(:key_validator) do |result|
            result.to_h.inject({}) do |acum, (k,v)|
              if v.is_a?(::Array) && array_subschema_keys.include?(k)
                acum[k] = []
              elsif v.is_a?(::Hash) && hash_subschema_keys.include?(k)
                acum[k] = {}
              else
                acum[k] = v
              end
              acum
            end
          end

          optional(:type) do
            (
              str? & included_in?(['array','boolean','null','number','object','string'])
            ) |
            (
              array? & filled? &
              each {
                str? & included_in?(['array','boolean','null','number','object','string'])
              }
            )
          end
          required(:type) if instance.size == 0
          optional(:'$id').filled(:string)
          optional(:'$schema').filled(:string)
          optional(:$title).maybe(:string)
          optional(:description).maybe(:string)
          optional(:default)
          optional(:examples)
          optional(:if).value(:hash)
          optional(:then).value(:hash)
          optional(:else).value(:hash)
          optional(:allOf).array(:hash)
          optional(:anyOf).array(:hash)
          optional(:oneOf).array(:hash)
          optional(:not)#.value(:hash)

          if instance.types&.include?('object') || instance.types.nil?
            optional(:required).value(:array?).array(:str?)
            optional(:properties).value(:hash)
          end

          if instance.types&.include?('array') || instance.types.nil?
            optional(:items)# todo value type
            optional(:contains)# todo value type
            optional(:additionalItems) { bool? | hash? }
            optional(:minItems).filled(:integer)
            optional(:maxItems).filled(:integer)
            optional(:uniqueItems).filled(:bool)
          end

          if instance.types&.include?('string') || instance.types.nil?
            optional(:minLength).filled(:integer)
            optional(:maxLength).filled(:integer)
            optional(:pattern).filled(:string)
            optional(:format).filled(:string)
          end

          if instance.types&.include?('number') || instance.types.nil?
            optional(:multipleOf).filled(:integer)
            optional(:minimum).filled(:integer)
            optional(:maximum).filled(:integer)
            optional(:exclusiveMinimum).filled(:integer)
            optional(:exclusiveMaximum).filled(:integer)
          end
          
          if instance.types
            optional(:const){
              instance.class::TYPES_TO_PREDICATES.call(self, instance.types)
            }
            optional(:enum){
              array? & 
              each {
                instance.class::TYPES_TO_PREDICATES.call(self, instance.types)
              }
            }
          else
            optional(:const)
            optional(:enum).value(:array?)
          end

        end
      end

      def valid_with_schema?
        schema_errors.empty?
      end

      # private
      
      def schema_errors(errors = {})

        # check for errors
        own_errors = validation_schema
          &.(self)
          &.errors
          &.to_h
          &.merge({}) || {}
        
        #set the errors on the hash
        own_errors.flatten_to_root.each do |relative_path, errors_array|
          path = (self.meta[:path] || []) + relative_path.to_s.split('.')
          errors.bury(*(path + [errors_array]))
        end

        #continue recurrsion for al subschema keys
        self[:properties]&.each do |k,v|
          v.schema_errors(errors)
        end
        
        #continue recurrsion for al subschema keys
        self.each do |key, value|
          case value
          when ::Array
            value.each do |v|
              v.schema_errors(errors) if v.is_a?(JsonSchemaForm::JsonSchema::Schema)
            end
          else
            value&.schema_errors(errors) if value.is_a?(JsonSchemaForm::JsonSchema::Schema)
          end
        end

        errors
      end

    end
  end
end