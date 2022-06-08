module JSF
  module Forms
    module Field
      class Shared < BaseHash

        include JSF::Forms::Field::Concerns::Base
    
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
              required(:component).value(included_in?: ['shared'])
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
              required(:visibility).hash do
                required(:label).filled(:bool)
              end
            end
          end
        end

        ##############
        ###METHODS####
        ##############
  
        # Gets json pointer $ref, should point to its pair (JSF::Forms::SharedRef, JSF::Forms::Form)
        # inside the form's 'definitions' key
        #
        # @return [String]
        def shared_definition_pointer
          self.dig(*[:$ref])
        end

        # Extracts the id from the json pointer
        #
        # @return [Integer]
        def db_id
          self.shared_definition_pointer&.match(/\d+\z/)&.to_s&.to_i
        end

        # Update the db id in the shared_definition_pointer
        #
        # @param [Integer]
        # @return [void]
        def db_id=(id)
          self[:$ref] = "#/definitions/#{JSF::Forms::Form.shared_ref_key(id)}"
        end
  
        # @return [JSF::Forms::SharedRef, JSF::Forms::Form]
        def shared_definition
          path = self.shared_definition_pointer&.sub('#/', '')&.split('/')&.map(&:to_sym)
          return if path.nil? || path.empty?
          find_parent do |current, _next|
            current.key?(:definitions)
          end&.dig(*path)
        end
    
      end
    end
  end
end