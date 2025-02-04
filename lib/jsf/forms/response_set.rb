# frozen_string_literal: true

module JSF
  module Forms

    #
    # Represents a collection of 'response values' that a JSF::Forms::Field class may be associated with.
    #
    class ResponseSet < BaseHash

      include JSF::Core::Schemable
      include JSF::Validations::Validatable
      include JSF::Validations::DrySchemaValidatable

      RESPONSE_TRANSFORM = ->(_attribute, responses_array, instance) {
        if responses_array.is_a? ::Array
          responses_array.map.with_index do |response, index|
            path = instance.meta[:path] + [:anyOf, index]
            JSF::Forms::Response.new(
              response,
              {
                meta: {
                  parent: instance,
                  path: path.map { |i| i.is_a?(Symbol) ? i.to_s : i }
                }
              }
            )
          end
        end
      }

      attribute? 'anyOf', default: ->(_data) { [].freeze }, transform: RESPONSE_TRANSFORM

      ###############
      # VALIDATIONS #
      ###############

      # @param passthru [Hash{Symbol => *}] Options passed
      # @return [Dry::Schema::JSON] Schema
      def dry_schema(_passthru)
        self.class.cache(nil) do
          Dry::Schema.JSON do
            config.validate_keys = true

            before(:key_validator) do |result| # result.to_h (shallow dup)
              result.to_h.tap do |h|
                h.each do |k, v|
                  h[k] = [] if v.is_a?(::Array) && k == 'anyOf'
                end
              end
            end

            required(:type).value(eql?: 'string')
            optional(:title).maybe(:string)
            required(:isResponseSet).filled(Types::True)
            optional(:sort).hash do
              required(:sortBy).value(included_in?: %w[alphabetical score])
              required(:sortOrder).value(included_in?: %w[asc desc])
            end
            required(:anyOf).array(:hash)
          end
        end
      end

      # # @param passthru [Hash{Symbol => *}]
      # def errors(**passthru)
      #   super
      # end

      # Checks if all JSF::Forms::Response are valid for a locale
      #
      # @param [String,Symbol] locale
      # @return [Boolean]
      def valid_for_locale?(locale = DEFAULT_LOCALE)
        self[:anyOf].empty? ||
        !!self[:anyOf].find { |r| r.valid_for_locale?(locale) }
      end

      ###########
      # METHODS #
      ###########

      # Adds a new response
      #
      # @param [Hash] definition
      # @return [Hash] added response
      def add_response(definition)
        self[:anyOf] = (self[:anyOf] || []) << definition
        self[:anyOf].last
      end

      # Removes a response based on a value
      #
      # @param [String] value
      # @return [NilClass, Hash]
      def remove_response_from_value(value)
        self[:anyOf] = self[:anyOf]&.reject { |r| r[:const] == value }
      end

      # Finds a response for a value
      #
      # @param [String] value
      # @return [NilClass, Hash]
      def get_response_from_value(value)
        self[:anyOf].find { |r| r[:const] == value }
      end

      # def get_failing_responses
      # end

      # def get_passing_responses
      # end

      def legalize!
        delete('isResponseSet')
        self
      end

      # Returns true if the response set has responses with scoring
      #
      # @return [Boolean]
      def scored?
        !!self[:anyOf]&.any? { |r| r.scored? }
      end

    end
  end
end