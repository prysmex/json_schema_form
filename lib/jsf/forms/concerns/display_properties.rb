module JSF
  module Forms
    module Concerns

      # Contains getters and setters for the following display property features:
      #
      # - hidden
      # - hideOnCreate
      # - sort
      # - label
      #
      module DisplayProperties

        # Get hidden
        #
        # @return [Boolean] true when hidden
        def hidden?
          !!dig(:displayProperties, :hidden)
        end

        # Set hidden
        #
        # @param [Boolean]
        # @return [Boolean]
        def hidden=(value)
          SuperHash::Utils.bury(self, :displayProperties, :hidden, value)
        end

        # Get hideOnCreate
        #
        # @return [Boolean] value
        def hideOnCreate?
          !!dig(:displayProperties, :hideOnCreate)
        end

        # Set hidden
        #
        # @param [Boolean] value
        # @return [Boolean]
        def hideOnCreate=(value)
          SuperHash::Utils.bury(self, :displayProperties, :hideOnCreate, value)
        end

        # Get sort
        #
        # @return [<Type>] <description>
        def sort
          dig(:displayProperties, :sort)
        end

        # Set sort
        #
        # @return [<Type>] <description>
        def sort=(value)
          SuperHash::Utils.bury(self, :displayProperties, :sort, value)
        end
        
        # Get the i18n label
        #
        # @param [String,Symbol] locale
        # @return [String]
        def i18n_label(locale = DEFAULT_LOCALE)
          dig(:displayProperties, :i18n, :label, locale)
        end
  
        # Set the i18n label
        #
        # @param [String,Symbol] locale
        # @param [String] locale
        # @return [String]
        def set_label_for_locale(label, locale = DEFAULT_LOCALE)
          SuperHash::Utils.bury(self, :displayProperties, :i18n, :label, locale, label)
        end

        # @return [Boolean]
        def visible(is_create:)
          !self.hidden? && !(is_create && self.hideOnCreate?)
        end

        # @return [String]
        def component
          dig(:displayProperties, :component)
        end

      end
    end
  end
end