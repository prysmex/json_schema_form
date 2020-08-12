module JsonSchemaForm
  class ResponseSet < ::SuperHash::Hasher

    instance_variable_set('@allow_dynamic_attributes', true)
    attr_reader :meta

    def initialize(obj, meta={}, &block)
      @meta = meta
      super(obj, &block)
    end

    FORM_RESPONSE_PROC = ->(instance, responsesArray) {
      if responsesArray.is_a? ::Array
        responsesArray.map.with_index do |response, index|
          path = instance.meta[:path] + [:responses, index]
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

    attribute? :responses, default: ->(instance) { [].freeze }, transform: FORM_RESPONSE_PROC

    ##################
    ###VALIDATIONS####
    ##################
    
    def validation_schema
      is_inspection = self.meta[:parent].is_inspection
      Dry::Schema.JSON do
        config.validate_keys = true
        required(:id) { int? | str? }
        required(:responses).array(:hash) do
        end
      end
    end

    def schema_validation_hash
      json = Marshal.load(Marshal.dump(self)) # new reference
      json[:responses]&.clear
      json
    end

    def valid_with_schema?
      schema_errors.empty?
    end

    def schema_errors
      errors_hash = validation_schema.(schema_validation_hash).errors.to_h.merge({})
      self[:responses]&.each.with_index do |response, index|
        response_errors = response.schema_errors
        unless response_errors.empty?
          errors_hash[:responses] ||= {}
          errors_hash[:responses][index] = response_errors
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

    # def get_failing_responses
    # end

    # def get_passing_responses
    # end

  end
end