module JsonSchemaForm
  module Field
    class Select < ::SuperHash::Hasher

      include ::JsonSchemaForm::Field::Base
      include JsonSchemaForm::Field::ResponseSettable

      ##################
      ###VALIDATIONS####
      ##################
      
      def validation_schema
        #TODO find a way to prevent enum from being valid
        Dry::Schema.define(parent: super) do
          required(:$ref).filled(:string)
          required(:displayProperties).hash do
            optional(:hiddenOnCreate).maybe(:bool)
            required(:isSelect).filled(Types::True)
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
        self.response_set
            .try(:[], :anyOf)
            &.reject{|property| property[:score].nil?}
            &.max_by{|property| property[:score] }
            .try(:[], :score)
      end

      def score_for_value(value)
        self.response_set
          .try(:[], :anyOf)
          &.find{|response| response[:const] == value}
          .try(:[], :score)
      end

      def value_fails?(value)
        response_set = self.response_set
        return false if response_set.nil?
        response_set[:anyOf]
          .find { |response| response[:const] == value }
          .try(:[], :failed) || false
      end

      def migrate!
        self[:'$ref'] = "#/definitions/#{self[:responseSetId]}"
        self.bury(:displayProperties, :isSelect, true)
        self.delete(:type)
        self.delete(:responseSetId)
      end

    end
  end
end