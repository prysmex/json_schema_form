module JSF
  module Forms
    module Field
      module Methods
        module ResponseSettable
  
          # used for validation
          REF_REGEX = /\A#\/definitions\/[a-z0-9\-_]+\z/

          # get the response_set_id, each field class should implement its own `RESPONSE_SET_PATH`
          #
          # @return [String]
          def response_set_id
            self.dig(*self.class::RESPONSE_SET_PATH)
          end
        
          # Set the response set id, each field class should implement its own `RESPONSE_SET_PATH`
          #
          # @todo should this raise an error if JSF::Forms::ResponseSet does not exists?
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
          # @param [String] locale
          # @return [String]
          def i18n_value(value, locale = DEFAULT_LOCALE)
            self
              .response_set
              .get_response_from_value(value)
              &.dig(:displayProperties, :i18n, locale)
          end
        
          # Add response set validations
          def own_errors(passthru)
            errors = super
            # validate response_set_id
            resp_id = self.response_set_id
            errors['$ref_path'] = "$ref must match this regex #{REF_REGEX}" if resp_id&.match(REF_REGEX).nil?
            errors['missing_response_set'] = "response set #{resp_id} was not found" if self.meta[:parent] && response_set.nil?
            errors
          end
        
        end
      end
    end
  end
end