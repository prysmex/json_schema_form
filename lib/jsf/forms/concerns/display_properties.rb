# frozen_string_literal: true

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
          if is_create
            !hidden? && !hideOnCreate?
          else
            !hidden?
          end
        end

        # @return [String]
        def component
          dig(:displayProperties, :component)
        end

        # @return [void]
        def compress!
          delete(:extra) if self[:extra]&.sort == %w[notes pictures reports]

          d_p = self[:displayProperties]
          return unless d_p

          d_p.compact! # remove all nil values

          d_p.delete(:hidden) if d_p[:hidden] == false
          d_p.delete(:hideOnCreate) if d_p[:hideOnCreate] == false
          d_p.delete(:modifyWarning) if d_p[:modifyWarning] == ''
          d_p.delete(:notes) if d_p[:notes] == ''
          d_p.delete(:pictures) if d_p[:pictures] == []
          d_p.delete(:disableScoring) if d_p[:disableScoring] == false
          d_p.delete(:readOnly) if d_p[:readOnly] == false
        end

      end
    end
  end
end