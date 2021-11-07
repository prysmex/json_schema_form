module JSF
  module Forms
    module Field
      class Component < BaseHash

        include ::JSF::Forms::Field::Methods::Base
    
        REF_REGEX = /\A#\/definitions\/\w+\z/

        ##################
        ###VALIDATIONS####
        ##################
    
        def validation_schema(passthru)
          skip_ref_presence = !run_validation?(passthru, self, :ref_presence)

          Dry::Schema.define(parent: super) do
            config.validate_keys = true
            if skip_ref_presence
              required(:$ref).maybe{ str? & format?(REF_REGEX) }
            else
              required(:$ref).filled{ str? & format?(REF_REGEX) }
            end
            required(:displayProperties).hash do
              optional(:hideOnCreate).filled(:bool)
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
            end
          end
        end

        ##############
        ###METHODS####
        ##############
  
        # Gets json pointer $ref, should point to its pair (JSF::Forms::ComponentRef, JSF::Forms::Form)
        # inside the form's 'definitions' key
        #
        # @return [String]
        def component_definition_pointer
          self.dig(*[:$ref])
        end
        
        # Sets json pointer $ref, should point to its pair (JSF::Forms::ComponentRef, JSF::Forms::Form)
        # inside the form's 'definitions' key
        #
        # @param [<Type>] pointer <description>
        # @return [String]
        def component_definition_pointer=(pointer)
          SuperHash::Utils.bury(self, *[:$ref], pointer)
        end

        # Extracts the id from the json pointer
        #
        # @return [Integer]
        def component_ref_id
          self.component_definition_pointer&.match(/\d+\z/)&.to_s&.to_i
        end
  
        # @return [JSF::Forms::ComponentRef, JSF::Forms::Form]
        def component_definition
          path = self.component_definition_pointer&.sub('#/', '')&.split('/')&.map(&:to_sym)
          return if path.nil? || path.empty?
          find_parent do |current, _next|
            current.key?(:definitions)
          end&.dig(*path)
        end
    
      end
    end
  end
end