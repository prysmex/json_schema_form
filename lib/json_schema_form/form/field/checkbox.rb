module JsonSchemaForm
  module Field
    class Checkbox < ::SuperHash::Hasher

      include ::JsonSchemaForm::Field::Base
      include JsonSchemaForm::Field::StrictTypes::Array
      include JsonSchemaForm::JsonSchema::DrySchemaValidatable
      include ::JsonSchemaForm::Field::ResponseSettable

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema
        #TODO find a way to prevent enum from being valid
        Dry::Schema.define(parent: super) do
          required(:uniqueItems)
          required(:items)
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

      def max_score
        scored_responses = self.response_set
          .try(:[], :responses)
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
            .try(:[], :responses)
            &.select {|response| value.include? response[:value]}
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
        response_set[:responses]
          &.find do |response|
            value.include?(response[:value]) && response[:failed] == true
          end
          .present?
      end

      def migrate!
        self[:items] = {'$ref': "#/definitions/#{self[:responseSetId]}"}
        self[:uniqueItems] = true
        self.delete(:responseSetId)
      end

    end
  end
end