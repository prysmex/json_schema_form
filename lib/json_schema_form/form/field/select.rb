module JsonSchemaForm
  module Field
    class Select < ::JsonSchemaForm::JsonSchema::String

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
        self.response_set
            .try(:[], :responses)
            &.max_by {|property| property[:score] || 0 }
            .try(:[], :score) || 0
      end

      def compile!
        self[:enum] = self.response_set.try(:[], :responses)&.map{|r| r[:value]} || []
      end

      def migrate!
      end

    end
  end
end