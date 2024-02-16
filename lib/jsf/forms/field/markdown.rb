module JSF
  module Forms
    module Field
      class Markdown < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Nullable
  
        set_strict_type('null')
  
        ##################
        ###VALIDATIONS####
        ##################
        
        def dry_schema(passthru)
          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(included_in?: ['markdown'])
              optional(:hidden).filled(:bool)
              optional(:hideOnCreate).filled(:bool)
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              required(:kind).maybe(:string)
              required(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
            required(:type)
          end
        end
  
        ##############
        ###METHODS####
        ##############

        def sample_value
          nil
        end
  
      end
    end
  end
end