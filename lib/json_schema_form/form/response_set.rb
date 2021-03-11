module JsonSchemaForm
  class ResponseSet < ::SuperHash::Hasher

    include JsonSchemaForm::JsonSchema::Schemable
    include JsonSchemaForm::JsonSchema::Validatable
    include JsonSchemaForm::JsonSchema::DrySchemaValidatable

    RESPONSE_PROC = ->(instance, responsesArray, attribute) {
      if responsesArray.is_a? ::Array
        responsesArray.map.with_index do |response, index|
          path = instance.meta[:path] + [:anyOf, index]
          JsonSchemaForm::Response.new(
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
        required(:anyOf).array(:hash) do
        end
      end
    end

    def schema_errors(errors = {})
      #own errors
      own_errors = validation_schema.(self).errors.to_h.merge({})

      #anyOf errors
      self[:anyOf]&.each.with_index do |response, index|
        response_errors = response.schema_errors
        unless response_errors.empty?
          own_errors[:anyOf] ||= {}
          own_errors[:anyOf][index] = response_errors
        end
      end

      #set to passed errors
      own_errors.flatten_to_root.each do |relative_path, errors_array|
        path = (self.meta[:path] || []) + relative_path.to_s.split('.')
        errors.bury(*(path + [errors_array]))
      end

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