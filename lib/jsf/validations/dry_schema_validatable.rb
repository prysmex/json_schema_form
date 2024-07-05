# frozen_string_literal: true

module JSF
  module Validations

    # Module that contains a logic powered by 'dry-schema' that can be used to validate a hash
    # by implementing `dry_schema`
    #
    # requirements:
    #
    # - `JSF::Validations::Validatable`
    #
    # TODO:
    #
    # - object:
    #   - patternProperties
    #   - additionalProperties
    #   - unevaluatedProperties
    #   - propertyNames
    #   - minProperties
    #   - maxProperties
    #
    # other:
    #   - dynamicRef
    #   - dynamicAnchor
    #   - dependentSchemas
    #   - dependentRequired
    #
    module DrySchemaValidatable

      def self.included(base)
        require 'dry-schema'

        base.extend ClassMethods
      end

      module ClassMethods
        # TODO: We can make an interface to support Rail's memory cache
        def cache(key, **, &)
          return yield if key.nil?

          @cache ||= {}
          @cache[key] ||= yield
        end
      end

      # Returns a Dry::Schema.JSON that can validate a Hash according to the
      # JSON Schema spec.
      #
      # @note override this method in target class
      #
      # @param passthru [Hash{Symbol => *}] Options passed
      # @return [Dry::Schema::JSON] Schema
      def dry_schema(passthru)
        # raise StandardError.new("Method not implemented in host class. #{self.class.name}")
      end

      # @param [Hash] passthru
      # @return [Hash]
      def dry_schema_errors(passthru)
        return {} unless run_validation?(passthru, :schema)

        dry_schema(passthru)
          .(as_json) # ActiveSupport::HashWithIndifferentAccess.new(to_h.as_json)
          .errors
          .to_h
          .deep_dup # important, otherwise something was getting polluted
      end

      # Returns a hash of errors
      #
      # @param passthru [Hash{Symbol => *}]
      # @return [Hash]
      def errors(**passthru)
        errors = dry_schema_errors(passthru)
        super.merge(errors)
      end

    end

    # Includes `DrySchemaValidatable` and adds a `dry_schema` that can be used to validate a hash
    # according with basic json-schema specs.
    #
    # requirements:
    #
    # - `JSF::Validations::Validatable` `dry_schema`
    module DrySchemaValidated
      include DrySchemaValidatable

      TYPES_TO_PREDICATES = proc do |ctx, types|
        map = {
          'boolean' => ['bool?'],
          'object' => ['hash?'],
          'string' => ['str?'],
          'number' => ['float?', 'int?'],
          'null' => ['nil?'],
          'array' => ['array?']
        }

        flat_predicate_names = types&.each_with_object([]) do |type, acum|
          mapped_predicate = map[type]
          case mapped_predicate
          when ::Array
            acum.concat(mapped_predicate)
          else
            acum.push(mapped_predicate)
          end
        end || %w[bool? hash? str? float? int? nil? array?]

        flat_predicate_names&.each_with_index&.inject(nil) do |acum_predicate, (predicate_name, i)|
          if i == 0
            ctx.send(predicate_name)
          else
            acum_predicate | ctx.send(predicate_name)
          end
        end
      end

      # Since the dry-schema validations are always done at a 'single' schema (without recursion),
      # we need to 'clear' all keys that may contain subschemas since dry-schema always validates
      # for unknown keys inside hashes and arrays
      #
      # @return [Hash]
      WITHOUT_SUBSCHEMAS_PROC = proc do |hash|
        hash.each do |k, v|
          if v.is_a?(::Array) && ARRAY_SUBSCHEMA_KEYS.include?(k)
            hash[k] = []
          elsif v.is_a?(::Hash) && (HASH_SUBSCHEMA_KEYS.include?(k) || JSF::NONE_SUBSCHEMA_HASH_KEYS_WITH_UNKNOWN_KEYS.include?(k))
            hash[k] = {}
          end
        end
      end

      # Returns a Dry::Schema.JSON that can validate a Hash according to the
      # JSON Schema spec.
      #
      # @param [Hash] passthru
      #
      # @return [Dry::Schema.JSON]
      def dry_schema(_passthru)
        instance = self

        Dry::Schema.JSON do
          config.validate_keys = true

          # need to clear data because jsonschema always tries to validate
          # for unknown keys inside hashes and arrays
          before(:key_validator) do |result| # result.to_h (shallow dup)
            WITHOUT_SUBSCHEMAS_PROC.call(result.to_h)
          end

          optional(:type) do
            (
              str? & included_in?(%w[array boolean null number object string])
            ) |
            (
              array? & filled? &
              each {
                str? & included_in?(%w[array boolean null number object string])
              }
            )
          end
          required(:type) if instance.size == 0
          optional(:$id).filled(:string)
          optional(:$anchor).filled(:string)
          optional(:$schema).filled(:string)
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
          optional(:not) # .value(:hash)
          optional(:$ref) # .value(:string)

          if instance.types&.include?('object') || instance.types.nil?
            optional(:required).value(:array?).array(:str?)
            optional(:properties).value(:hash)
            optional(:$defs).value(:hash)
          end

          if instance.types&.include?('array') || instance.types.nil?
            optional(:items) # TODO: value type
            optional(:contains) # TODO: value type
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
            optional(:const) {
              instance.class::TYPES_TO_PREDICATES.call(self, instance.types)
            }
            optional(:enum) {
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

    end
  end
end