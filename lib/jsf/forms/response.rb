# frozen_string_literal: true

module JSF
  module Forms

    #
    # Represents a 'single' response in a JSF::Forms::ResponseSet
    #
    class Response < BaseHash

      include JSF::Core::Schemable
      include JSF::Validations::Validatable
      include JSF::Validations::DrySchemaValidatable

      ###############
      # VALIDATIONS #
      ###############

      # @param passthru [Hash{Symbol => *}] Options passed
      # @return [Dry::Schema::JSON] Schema
      def dry_schema(passthru)
        scoring = run_validation?(passthru, :scoring, optional: true)
        failing = run_validation?(passthru, :failing, optional: true)

        Dry::Schema.JSON do
          config.validate_keys = true
          required(:type).filled(Types::String.enum('string'))
          required(:const).value(:string)
          required(:displayProperties).hash do
            required(:i18n).hash do
              AVAILABLE_LOCALES.each do |locale|
                optional(locale.to_sym).maybe(:string)
              end
            end
            optional(:color).maybe(:string)
            optional(:tags).value(:array?).array(:str?)
          end
          if scoring
            required(:enableScore).value(Types::True) # deprecate?
            required(:score) { nil? | ((int? | float?) > gteq?(0)) }
          end
          required(:failed).value(:bool) if failing
        end
      end

      # # @param passthru [Hash{Symbol => *}]
      # def errors(**passthru)
      #   super
      # end

      # Checks if locale is valid
      #
      # @param [String, Symbol] locale
      # @return [Boolean]
      def valid_for_locale?(locale = DEFAULT_LOCALE)
        !dig(:displayProperties, :i18n, locale).to_s.empty?
      end

      ###########
      # METHODS #
      ###########

      # Sets a locale
      #
      # @param [String] label
      # @param [String,Symbol] locale
      # @return [void]
      def set_translation(label, locale = DEFAULT_LOCALE)
        SuperHash::Utils.bury(self, :displayProperties, :i18n, locale, label)
      end

      def legalize!
        delete(:displayProperties)
        delete(:enableScore)
        delete(:failed)
        delete(:score)
        self
      end

      # Checks if the response has an assigned score value
      #
      # @return [Boolean]
      def scored?
        !self[:score].nil?
      end

    end
  end
end
