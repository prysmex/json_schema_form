module JSF
  module Forms
    module Field
      module Concerns
        module ResponseSettable
  
          # used for validation
          REF_REGEX = /\A#\/definitions\/[a-z0-9\-_]+\z/

          ##################
          ###VALIDATIONS####
          ##################

          # # Consider response set
          # #
          # # @param [] locale
          # # @return [Boolean]
          # def valid_for_locale?(locale = DEFAULT_LOCALE)
          #   field_is_valid = super

          #   set = self.response_set
          #   field_is_valid && (set.nil? || set.valid_for_locale?(locale))
          # end

          ##############
          ###METHODS####
          ##############

          # get the response_set_id, each field class should implement its own `RESPONSE_SET_PATH`
          #
          # @return [String]
          def response_set_id
            self.dig(*self.class::RESPONSE_SET_PATH)
          end
        
          # Set the response set id, each field class should implement its own `RESPONSE_SET_PATH`
          #
          # @param id [String] id of the JSF::Forms::ResponseSet
          # @return [String]
          def response_set_id=(id)
            SuperHash::Utils.bury(self, *self.class::RESPONSE_SET_PATH, "#/definitions/#{id}")
          end
        
          # get the field's response set. It looks for it in the first parent with the `definitions` key
          #
          # @return [JSF::Forms::ResponseSet]
          def response_set
            path = self.response_set_id&.sub('#/', '')&.split('/')&.map(&:to_sym)
            return if path.nil? || path.empty?

            find_parent do |current, _next|
              current.key?(:definitions)
            end&.dig(*path)
          end

          # get the translation for a value in the field's response set
          #
          # @param [Object] value
          # @param [String,Symbol] locale
          # @return [String]
          def i18n_value(value, locale = DEFAULT_LOCALE)
            self
              .response_set
              &.get_response_from_value(value)
              &.dig(:displayProperties, :i18n, locale)
          end

          # Returns true if field contributes to scoring
          #
          # @override
          #
          # @return [Boolean]
          def scored?
            !!self.response_set&.scored?
          end
        
        end
      end
    end
  end
end