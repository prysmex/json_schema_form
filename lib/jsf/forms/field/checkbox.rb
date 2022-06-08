module JSF
  module Forms
    module Field
      class Checkbox < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Arrayable
        include JSF::Forms::Field::Concerns::ResponseSettable
  
        RESPONSE_SET_PATH = [:items, :$ref]
  
        set_strict_type('array')
  
        ##################
        ###VALIDATIONS####
        ##################
        
        def validation_schema(passthru)
          #TODO find a way to prevent enum from being valid
          skip_ref_presence = !run_validation?(passthru, self, :ref_presence)

          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(included_in?: ['checkbox'])
              optional(:hidden).filled(:bool)
              optional(:hideOnCreate).filled(:bool)
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              required(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            if passthru[:is_inspection] || passthru[:is_shared]
              optional(:extra).value(:array?).array(:str?).each(included_in?: ['reports', 'notes', 'pictures'])
            end
            required(:items).hash do
              if skip_ref_presence
                required(:$ref).maybe{ str? & format?(::JSF::Forms::Field::Concerns::ResponseSettable::REF_REGEX) }
              else
                required(:$ref).filled{ str? & format?(::JSF::Forms::Field::Concerns::ResponseSettable::REF_REGEX) }
              end
            end
            required(:type)
            required(:uniqueItems)
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

        def sample_value
          response_set = self.response_set
          return [] if response_set.nil?
          response_set[:anyOf].sample(2)

          self.response_set
            &.dig(:anyOf)
            &.sample(2)
            &.map{|o| o&.dig(:const) }
        end
  
      end
    end
  end
end