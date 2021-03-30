module SchemaForm
  module Field
    class Checkbox < ::SuperHash::Hasher

      include ::SchemaForm::Field::Base
      include JsonSchema::StrictTypes::Array
      include ::SchemaForm::Field::ResponseSettable

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema(passthru)
        #TODO find a way to prevent enum from being valid
        Dry::Schema.define(parent: super) do
          required(:type)
          required(:uniqueItems)
          required(:items).hash do
            required(:'$ref').filled(:string)
          end
          required(:displayProperties).hash do
            optional(:hiddenOnCreate).maybe(:bool)
            required(:pictures).value(:array?).array(:str?)
            required(:i18n).hash do
              required(:label).hash do
                optional(:es).maybe(:string)
                optional(:en).maybe(:string)
              end
            end
            required(:visibility).hash do
              required(:label).filled(:bool)
            end
            required(:sort).filled(:integer)
            required(:hidden).filled(:bool)
          end
        end
      end

      ##############
      ###METHODS####
      ##############

      def response_set_id
        self.dig(:items, :$ref)
      end

      def max_score
        scored_responses = self.response_set
          &.[](:anyOf)
          &.reduce(nil) do |sum,response|
            if response[:score].nil?
              sum
            else
              sum.to_f + response[:score]
            end
          end
      end

      def score_for_value(value)
        case value
        when ::Array
          self.response_set
            &.[](:anyOf)
            &.select {|response| value.include? response[:const]}
            &.reduce(nil) do |sum,response|
              if response[:score].nil?
                sum
              else
                sum.to_f + response[:score]
              end
            end
        else
          nil
        end
      end

      def value_fails?(value)
        response_set = self.response_set
        return false if response_set.nil? || value.nil?
        !response_set[:anyOf]
          &.find do |response|
            value.include?(response[:const]) && response[:failed] == true
          end.nil?
      end

      def migrate!
        self[:items] = JsonSchema::Schema.new({'$ref': "#/definitions/#{self[:responseSetId]}"})
        self.delete(:minItems)
        self.delete(:maxItems)
        self[:uniqueItems] = true
        self.delete(:responseSetId)
      end

    end
  end
end