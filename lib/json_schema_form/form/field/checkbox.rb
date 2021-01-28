module JsonSchemaForm
  module Field
    class Checkbox < ::JsonSchemaForm::JsonSchema::Array

      include ::JsonSchemaForm::Field::InstanceMethods
      include ::JsonSchemaForm::Field::ResponseSettable

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema
        #TODO find a way to prevent enum from being valid
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:responseSetId) { int? | str? }
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

      def schema_validation_hash
        json = super
        enum_locales = json.dig(:displayProperties, :i18n, :enum)
        enum_locales&.each do |lang, locales|
          locales&.clear
        end
        json
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

      def compile!
        self[:items] = {
          :"$id" => '/properties/checkbox4738/items',
          type: 'string',
          enum: self.response_set.try(:[], :responses)&.map{|r| r[:value]} || [],
          :'$schema' => 'http://json-schema.org/draft-07/schema#'
        }
      end

      def migrate!
      end

    end
  end
end