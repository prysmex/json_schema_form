module JSF
  module Forms
    module Field
      class Static < BaseHash

        include ::JSF::Forms::Field::Methods::Base
        include JSF::Core::Type::Nullable
  
        set_strict_type('null')
  
        ##################
        ###VALIDATIONS####
        ##################
  
        def validation_schema(passthru)
          can_be_hidden = (passthru[:hideable_static_fields] || []).map(&:to_s).include?(self.key_name)
          can_be_hidden_on_create = (passthru[:hideable_on_create_static_fields] || []).map(&:to_s).include?(self.key_name)
          Dry::Schema.define(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(included_in?: ['static'])
              optional(:hidden).filled(:bool) if can_be_hidden
              optional(:hideOnCreate).filled(:bool) if can_be_hidden_on_create
              required(:sort).filled(:integer)
            end
            optional(:static).filled(Types::True)
            required(:type)
          end
        end

        def valid_for_locale?(locale = DEFAULT_LOCALE)
          true
        end

        ##################
        #####METHODS######
        ##################
  
      end
    end
  end
end