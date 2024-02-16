module JSF
  module Forms
    module Field
      class Static < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Nullable
  
        set_strict_type('null')
  
        ##################
        ###VALIDATIONS####
        ##################
  
        def dry_schema(passthru)
          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(included_in?: ['static'])
              optional(:hidden).filled(:bool)
              optional(:hideOnCreate).filled(:bool)
              required(:sort).filled(:integer)
            end
            required(:type)
          end
        end

        def valid_for_locale?(locale = DEFAULT_LOCALE)
          true
        end

        ##################
        #####METHODS######
        ##################

        def sample_value
          nil
        end
  
      end
    end
  end
end