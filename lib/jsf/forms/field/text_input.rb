module JSF
  module Forms
    module Field
      class TextInput < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Stringable
  
        set_strict_type('string')
  
        ##################
        ###VALIDATIONS####
        ##################
  
        def validation_schema(passthru)
          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(included_in?: ['text_input'])
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
              required(:textarea).filled(:bool)
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            optional(:extra).value(:array?).array(:str?).each(included_in?: ['reports', 'notes', 'pictures']) if passthru[:is_inspection] || passthru[:is_shared]
            required(:type)
          end
        end
  
        ##################
        #####METHODS######
        ##################

        def sample_value
          string_length = 8
          rand(36**string_length).to_s(36)
        end
  
      end
    end
  end
end