module JSF
  module Forms
    class ResponseSet < BaseHash

      include JSF::Core::Schemable
      include JSF::Validations::Validatable
  
      RESPONSE_PROC = ->(attribute, responsesArray, instance) {
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
  
      attribute? 'anyOf', default: ->(data) { [].freeze }, transform: RESPONSE_PROC
  
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
  
      def own_errors(passthru)
        JSF::Validations::DrySchemaValidatable::SCHEMA_ERRORS_PROC.call(validation_schema(passthru), self)
      end
  
      ##############
      ###METHODS####
      ##############
  
      def add_response(definition)
        self[:anyOf] = (self[:anyOf] || []) << definition
        self[:anyOf].last
      end
  
      # def remove_response
      # end
  
      def get_response_from_value(value)
        self[:anyOf].find{|r| r[:const] == value }
      end
  
      def valid_for_locale?(locale = DEFAULT_LOCALE)
        self[:anyOf].find{|r| r.valid_for_locale?(locale) == false }.nil?
      end
  
      # def get_failing_responses
      # end
  
      # def get_passing_responses
      # end
  
    end
  end
end