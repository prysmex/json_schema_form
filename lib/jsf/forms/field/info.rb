module JSF
  module Forms
    module Field
      class Info < BaseHash

        include ::JSF::Forms::Field::Methods::Base
        include JSF::Core::Type::Nullable
  
        set_strict_type('null')
  
        ##################
        ###VALIDATIONS####
        ##################
        
        def validation_schema(passthru)
          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              optional(:hidden).filled(:bool)
              optional(:hideOnCreate).filled(:bool)
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              required(:icon).filled(:string)
              required(:kind).filled(:string)
              required(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:useInfo).filled(:bool)
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
  
      end
    end
  end
end