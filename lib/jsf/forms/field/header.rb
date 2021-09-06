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
            required(:type)
            required(:displayProperties).hash do
              optional(:hideOnCreate).filled(:bool)
              required(:pictures).value(:array?).array(:str?)
              required(:i18n).hash do
                required(:label).hash do
                  AVAILABLE_LOCALES.each do |locale|
                    optional(locale.to_sym).maybe(:string)
                  end
                end
              end
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
              required(:sort).filled(:integer)
              optional(:hidden).filled(:bool)
              required(:useHeader).filled(:bool)
              required(:level).filled(Types::Integer.constrained(lteq: 2))
            end
          end
        end
  
        ##############
        ###METHODS####
        ##############
  
        def migrate!
        end
  
      end
    end
  end
end