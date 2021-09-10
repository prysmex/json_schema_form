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
          skip_ref_presence = passthru[:skip_ref_presence]

          Dry::Schema.define(parent: super) do
            config.validate_keys = true
            if skip_ref_presence
              required(:$ref).maybe{ str? & format?(/\A#\/definitions\/\w+\z/) }
            else
              required(:$ref).filled{ str? & format?(/\A#\/definitions\/\w+\z/) }
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
    
        # @param passthru [Hash{Symbol => *}]
        def own_errors(passthru)
          errors = super

          if !component_definition_id.nil?
            # response should be found
            if self.component_definition.nil?
              errors['component_definition_not_found'] = "component #{component_definition_id} was not found"
            end
          end

          errors
        end

        ##############
        ###METHODS####
        ##############
  
        def component_definition_id
          self.dig(*[:$ref])
        end
  
        def component_definition_id=(id)
          SuperHash::Utils.bury(self, *[:$ref], "#/definitions/#{id}")
        end
  
        def component_definition
          path = self.component_definition_id&.sub('#/', '')&.split('/')&.map(&:to_sym)
          return if path.nil? || path.empty?
          find_parent do |current, _next|
            current.key?(:definitions)
          end&.dig(*path)
        end
    
      end
    end
  end
end