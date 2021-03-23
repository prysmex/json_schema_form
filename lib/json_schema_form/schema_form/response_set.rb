module SchemaForm
  class ResponseSet < ::SuperHash::Hasher

    include JsonSchema::SchemaMethods::Schemable

    RESPONSE_PROC = ->(instance, responsesArray, attribute) {
      if responsesArray.is_a? ::Array
        responsesArray.map.with_index do |response, index|
          path = instance.meta[:path] + [:anyOf, index]
          SchemaForm::Response.new(
            response,
            {
              parent: instance,
              path: path
            }
          )
        end
      end
    }

    attribute? :anyOf, default: ->(instance) { [].freeze }, transform: RESPONSE_PROC

    ##################
    ###VALIDATIONS####
    ##################
    
    def validation_schema
      Dry::Schema.JSON do
        config.validate_keys = true

        before(:key_validator) do |result|
          result.to_h.inject({}) do |acum, (k,v)|
            if v.is_a?(::Array) && k == :anyOf
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

    def own_errors
      JsonSchema::Validations::DrySchemaValidatable::OWN_ERRORS_PROC.call(validation_schema, self)
    end

    def errors(errors, passthru)
      #own errors
      own_errors = self.own_errors

      #anyOf errors (responses)
      self[:anyOf]&.each.with_index do |response, index|
        response_errors = response.errors(is_inspection: passthru[:is_inspection])
        unless response_errors.empty?
          own_errors[:anyOf] ||= {}
          own_errors[:anyOf][index] = response_errors
        end
      end

      JsonSchema::Validations::Validatable::BURY_ERRORS_PROC.call(own_errors, errors, self.meta[:path])

      errors
    end

    ##############
    ###METHODS####
    ##############

    # def add_response
    # end

    # def remove_response
    # end

    def get_response_from_value(value)
      self[:anyOf].find{|r| r[:const] == value }
    end

    def valid_for_locale?(locale = :es)
      self[:anyOf].find{|r| r.valid_for_locale?(locale) == false }.nil?
    end

    # def get_failing_responses
    # end

    # def get_passing_responses
    # end

  end
end