module JsonSchemaForm
  module Field
    class Select < ::JsonSchemaForm::Type::String

      include ::JsonSchemaForm::Field::FieldMethods
      
      def validation_schema
        #TODO find a way to prevent enum from being valid
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          required(:responseSetId) { int? | str? }
          required(:displayProperties).hash do
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

      def migrate!
        if self[:responseSetId].nil?

          # this would require updating all document values so they match the response_set values
          # equivalent_response_set = root_form.response_sets.find do |id, definition|
          #   [:en, :es].each do |locale|
          #     response_set_i18n_values = definition[:responses].map do |obj|
          #       i18n_value = obj.dig(:displayProperties, :i18n, locale)
          #     end.compact
          #     enum_i18n_values = self[:enum].map do |value|
          #       self.dig(:displayProperties, :i18n, :enum, locale, value.to_sym)
          #     end.compact
          #     return response_set_i18n_values.length == (response_set_i18n_values & enum_i18n_values).length
          #   end
          # end

          if false
            # puts 'using existing response set'
            # self[:responseSetId] = equivalent_response_set[0].to_s
          else
            puts 'creating new response set'
            id = SecureRandom.uuid
            new_response_set = {
              responses: []
            }
            
            options = self.dig(:enum)
            unless options.nil?
              options.each do |opt|
                new_response_set[:responses].push(
                  {
                    value: opt,
                    score: nil,
                    failed: false,
                    displayProperties: {
                      i18n: {
                        en: self.dig(:displayProperties, :i18n, :enum, :en, opt.to_sym),
                        es: self.dig(:displayProperties, :i18n, :enum, :es, opt.to_sym)
                      },
                      color: nil
                    }
                  }
                )
              end
            end
            root_form.add_response_set(id, new_response_set)
            self[:responseSetId] = id
          end
          self.dig(:displayProperties, :i18n).delete(:enum)
          self.delete(:enum)
        end
      end

    end
  end
end