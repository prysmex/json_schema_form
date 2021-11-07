module JSF
  module Forms
    module Field
      class Select < BaseHash

        include ::JSF::Forms::Field::Methods::Base
        include JSF::Forms::Field::Methods::ResponseSettable
  
        RESPONSE_SET_PATH = [:$ref]
  
        ##################
        ###VALIDATIONS####
        ##################
        
        def validation_schema(passthru)
          skip_ref_presence = !run_validation?(passthru, self, :ref_presence)

          #TODO find a way to prevent enum from being valid
          Dry::Schema.define(parent: super) do
            if skip_ref_presence
              required(:$ref).maybe{ str? & format?(::JSF::Forms::Field::Methods::ResponseSettable::REF_REGEX) }
            else
              required(:$ref).filled{ str? & format?(::JSF::Forms::Field::Methods::ResponseSettable::REF_REGEX) }
            end
            required(:displayProperties).hash do
              optional(:hideOnCreate).filled(:bool)
              required(:isSelect).filled(Types::True)
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
  
        # @return [Integer, Float]
        def max_score
          self.response_set
              &.[](:anyOf)
              &.reject{|property| property[:score].nil?}
              &.max_by{|property| property[:score] }
              &.[](:score)
        end
  
        # Returns the score of a JSF::Forms::Response for a value
        #
        # @param [String]
        # @return [Integer, Float]
        def score_for_value(value)
          self.response_set
            &.[](:anyOf)
            &.find{|response| response[:const] == value}
            &.[](:score)
        end

        # Checks the JSF::Forms::Response for a value is considered 'failed'
        #
        # @param [String]
        # @return [Boolean]
        def value_fails?(value)
          response_set = self.response_set
          return false if response_set.nil?
          response_set[:anyOf]
            .find { |response| response[:const] == value }
            &.[](:failed) || false
        end
  
        def migrate!
        end
  
      end
    end
  end
end