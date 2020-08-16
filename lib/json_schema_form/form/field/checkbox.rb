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
            required(:pictures).array(:string)
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
            .reduce(0){|sum,response| sum + (response[:score] || 0) }
      end

      def compile!
        self[:items] = {
          :"$id" => '/properties/checkbox4738/items',
          type: 'string',
          enum: self.response_set.try(:[], :responses)&.map{|r| r[:value]} || [],
          :'$schema' => 'http://json-schema.org/draft-07/schema#'
        }
      end

      #V2.11.O => V2.12.0 migration
      def migrate!
        if self[:responseSetId].nil?

          puts 'creating new response set'
          id = SecureRandom.uuid
          new_response_set = {
            responses: []
          }
          
          options = self.dig(:items, :enum)
          unless options.nil?
            options.each do |opt|
              
              current_response_set = {
                value: opt,
                displayProperties: {
                  i18n: {
                    en: self.dig(:displayProperties, :i18n, :enum, :en, opt.to_sym),
                    es: self.dig(:displayProperties, :i18n, :enum, :es, opt.to_sym)
                  }
                }
              }

              if root_form.is_inspection
                current_response_set[:enableScore] = true
                current_response_set[:score] = nil
                current_response_set[:failed] = false
                current_response_set[:displayProperties][:color] = nil
              end

              new_response_set[:responses].push(current_response_set)
            end
          end
          root_form.add_response_set(id, new_response_set)
          self[:responseSetId] = id

          self.dig(:displayProperties, :i18n).delete(:enum)
          self.delete(:items)
        end
      end

    end
  end
end