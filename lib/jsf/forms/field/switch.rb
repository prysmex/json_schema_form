# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class Switch < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Booleanable

        set_strict_type('boolean')

        ###############
        # VALIDATIONS #
        ###############

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          extras = run_validation?(passthru, :extras, optional: true)
          scoring = run_validation?(passthru, :scoring, optional: true)

          self.class.cache("#{hide_on_create}#{extras}#{scoring}") do
            Dry::Schema.JSON(parent: super) do
              optional(:default).value(:bool)
              required(:displayProperties).hash do
                required(:component).value(eql?: 'switch')
                optional(:disableScoring) { bool? } if scoring
                optional(:hidden).filled(:bool)
                optional(:hideOnCreate).filled(:bool) if hide_on_create
                required(:i18n).hash do
                  required(:falseLabel).hash do
                    AVAILABLE_LOCALES.each do |locale|
                      optional(locale.to_sym).maybe(:string)
                    end
                  end
                  required(:trueLabel).hash do
                    AVAILABLE_LOCALES.each do |locale|
                      optional(locale.to_sym).maybe(:string)
                    end
                  end
                  required(:label).hash do
                    AVAILABLE_LOCALES.each do |locale|
                      optional(locale.to_sym).maybe(:string)
                    end
                  end
                  optional(:helpText).hash do
                    AVAILABLE_LOCALES.each do |locale|
                      optional(locale.to_sym).maybe(:string)
                    end
                  end
                end
                optional(:pictures).value(:array?).array(:str?)
                required(:sort).filled(:integer)
                required(:visibility).hash do
                  required(:label).filled(:bool)
                end
              end
              optional(:extra).value(:array?).array(:str?).each(included_in?: %w[reports notes pictures]) if extras
              required(:type)
            end
          end
        end

        # @param [String, Symbol] locale
        # @return [Boolean]
        def valid_for_locale?(locale = DEFAULT_LOCALE)
          super &&
            !dig(:displayProperties, :i18n, :trueLabel, locale).to_s.empty? &&
            !dig(:displayProperties, :i18n, :falseLabel, locale).to_s.empty?
        end

        ###########
        # METHODS #
        ###########

        # get the translation for a value
        #
        # @param [] value
        # @param [String,Symbol] locale
        # @return [String]
        def i18n_value(value, locale = DEFAULT_LOCALE)
          label_key = if value == true
            :trueLabel
          elsif value == false
            :falseLabel
          end
          dig(:displayProperties, :i18n, label_key, locale)
        end

        # @return [1]
        def max_score
          1
        end

        # Returns a score for a value
        #
        # @param [Boolean, Nilclass]
        # @return [1,0,nil]
        def score_for_value(value)
          case value
          when true
            1
          when false
            0
          when nil
            nil
          else
            raise TypeError.new("value must be boolean or nil, got: #{value.class}")
          end
        end

        # Returns true if field contributes to scoring
        #
        # @override
        #
        # @return [Boolean]
        def scored?
          dig(:displayProperties, :disableScoring) != true
        end

        def sample_value
          [true, false].sample
        end

      end
    end
  end
end