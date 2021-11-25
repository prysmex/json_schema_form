module JSF
  module Forms
    module Field
      class Header < BaseHash

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
              required(:level).filled(Types::Integer.constrained(lteq: 2))
              required(:pictures).value(:array?).array(:str?)
              required(:sort).filled(:integer)
              required(:useHeader).filled(:bool)
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