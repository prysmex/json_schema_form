module JSF
  module Forms
    
    #
    # Represents a collection of 'response values' that a JSF::Forms::Field class may be associated with.
    #
    class ResponseSet < BaseHash

      include JSF::Core::Schemable
      include JSF::Validations::Validatable
  
      RESPONSE_TRANSFORM = ->(attribute, responsesArray, instance) {
        if responsesArray.is_a? ::Array
          responsesArray.map.with_index do |response, index|
            path = instance.meta[:path] + [:anyOf, index]
            JSF::Forms::Response.new(
              response,
              {
                parent: instance,
                path: path.map{|i| i.is_a?(Symbol) ? i.to_s : i }
              }
            )
          end
        end
      }
  
      attribute? 'anyOf', default: ->(data) { [].freeze }, transform: RESPONSE_TRANSFORM
  
      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema(passthru)
        Dry::Schema.JSON do
          config.validate_keys = true
  
          before(:key_validator) do |result|
            result.to_h.inject({}) do |acum, (k,v)|
              if v.is_a?(::Array) && k == 'anyOf'
                acum[k] = []
              else
                acum[k] = v
              end
              acum
            end
          end
  
          required(:type).filled(Types::String.enum('string'))
          optional(:title).maybe(:string)
          required(:isResponseSet).filled(Types::True)
          required(:anyOf).array(:hash) do
          end
        end
      end

      # @param passthru [Hash{Symbol => *}]
      def own_errors(passthru={})
        JSF::Validations::DrySchemaValidatable::SCHEMA_ERRORS_PROC.call(validation_schema(passthru), self)
      end

      # Checks if all JSF::Forms::Response are valid for a locale
      #
      # @param [String,Symbol] locale
      # @return [Boolean]
      def valid_for_locale?(locale = DEFAULT_LOCALE)
        !!self[:anyOf].find{|r| r.valid_for_locale?(locale) }
      end
  
      ##############
      ###METHODS####
      ##############
  
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
      def get_response_from_value(value)
        self[:anyOf] = self[:anyOf]&.reject{|r| r[:const] == value }
      end
  
      # Finds a response for a value
      #
      # @param [String] value
      # @return [NilClass, Hash]
      def get_response_from_value(value)
        self[:anyOf].find{|r| r[:const] == value }
      end
  
      # def get_failing_responses
      # end
  
      # def get_passing_responses
      # end
  
    end
  end
end