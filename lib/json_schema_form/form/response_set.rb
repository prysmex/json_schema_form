module JsonSchemaForm
  class ResponseSet < ::SuperHash::Hasher

    instance_variable_set('@allow_dynamic_attributes', true)
    attr_reader :meta

    def initialize(obj, meta={}, options={}, &block)
      @meta = meta
      super(obj, options, &block)
    end

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

    attribute :anyOf, default: ->(instance) { [].freeze }, transform: RESPONSE_PROC
    attribute :type

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
        optional(:title) { str? }
        required(:anyOf).array(:hash) do
        end
      end
    end

    def has_errors?
      schema_errors.empty?
    end

    def schema_errors
      errors_hash = validation_schema.(self).errors.to_h.merge({})
      self[:anyOf]&.each.with_index do |response, index|
        response_errors = response.schema_errors
        unless response_errors.empty?
          errors_hash[:anyOf] ||= {}
          errors_hash[:anyOf][index] = response_errors
        end
      end
      errors_hash
    end

    ##############
    ###METHODS####
    ##############

    # def add_response
    # end

    # def remove_response
    # end

    def get_response_from_value(value)
      self[:responses].find{|r| r[:value] == value }
    end

    def valid_for_locale?(locale = :es)
      self[:responses].find{|r| r.valid_for_locale?(locale) == false }.nil?
    end

    # def get_failing_responses
    # end

    # def get_passing_responses
    # end

  end
end