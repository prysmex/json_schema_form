module JSF
  module Forms
    module Field
      class Checkbox < BaseHash

        include JSF::Forms::Field::Methods::Base
        include JSF::Core::Type::Arrayable
        include JSF::Forms::Field::Methods::ResponseSettable
  
        RESPONSE_SET_PATH = [:items, :$ref]
  
        set_strict_type('array')
  
        ##################
        ###VALIDATIONS####
        ##################
        
        def validation_schema(passthru)
          #TODO find a way to prevent enum from being valid
          skip_ref_presence = passthru[:skip_ref_presence]
          Dry::Schema.define(parent: super) do
            required(:type)
            required(:uniqueItems)
            required(:items).hash do
              if skip_ref_presence
                required(:$ref).maybe{ str? & format?(::JSF::Forms::Field::Methods::ResponseSettable::REF_REGEX) }
              else
                required(:$ref).filled{ str? & format?(::JSF::Forms::Field::Methods::ResponseSettable::REF_REGEX) }
              end
            end
            required(:displayProperties).hash do
              optional(:hideOnCreate).filled(:bool)
              required(:pictures).value(:array?).array(:str?)
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
              required(:sort).filled(:integer)
              optional(:hidden).filled(:bool)
            end
          end
        end
  
        ##############
        ###METHODS####
        ##############
  
        # Returns the maximum attainable score based on the field's ResponseSet
        #
        # @return [NilClass, Integer, Float]
        def max_score
          self.response_set
            &.[](:anyOf)
            &.reduce(nil) do |sum,response|
              [
                sum,
                response[:score]
              ].compact.inject(&:+)
            end
        end

        # Returns the sum of the score matching JSF::Forms::Response
        #
        # @param [Array]
        # @return [Integer, Float]
        def score_for_value(value)
          self.response_set
            &.[](:anyOf)
            &.select {|response| value.include? response[:const]}
            &.reduce(nil) do |sum,response|
              [
                sum,
                response[:score]
              ].compact.inject(&:+)
            end
        end
  
        # Checks if any of the matching JSF::Forms::Response are considered 'failed'
        #
        # @param [Array] value
        # @return [Boolean]
        def value_fails?(value)
          response_set = self.response_set
          return false if response_set.nil? || value.nil?
          !response_set[:anyOf]
            &.find do |response|
              value.include?(response[:const]) && response[:failed] == true
            end.nil?
        end
  
        def migrate!
        end
  
      end
    end
  end
end