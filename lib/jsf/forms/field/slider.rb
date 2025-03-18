# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class Slider < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Numberable

        MAX_ENUM_SIZE = 25
        MAX_PRECISION = 5

        set_strict_type('number')

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
              before(:key_validator) do |result| # result.to_h (shallow dup)
                result.to_h.deep_dup.tap do |h|
                  h.dig('displayProperties', 'i18n', 'enum')&.each_value do |data|
                    data&.clear if data.respond_to?(:clear)
                  end
                end
              end

              required(:displayProperties).hash do
                required(:component).value(eql?: 'slider')
                optional(:disableScoring) { bool? } if scoring
                optional(:hideOnCreate).filled(:bool) if hide_on_create
                optional(:hidden).filled(:bool)
                required(:i18n).hash do
                  # TODO: create two types of sliders and remove this when only numbers
                  required(:enum).hash do
                    AVAILABLE_LOCALES.each do |locale|
                      optional(locale.to_sym).maybe(:hash)
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
              required(:enum).value(min_size?: 2, max_size?: MAX_ENUM_SIZE).array { (int? | float?) & gteq?(0) }
              optional(:extra).value(:array?).array(:str?).each(included_in?: %w[reports notes pictures]) if extras
              required(:type)
            end
          end
        end

        # @param passthru [Hash{Symbol => *}]
        def errors(**passthru)
          errors = {}

          # extra enum validations
          if self[:enum].is_a?(Array)

            # enum precision
            if run_validation?(passthru, :enum_precision)
              precision_errors = self[:enum].select do |value|
                value != value.round(MAX_PRECISION)
              end
              if !precision_errors.empty?
                add_error_on_path(
                  errors,
                  'enum',
                  "invalid enum values #{precision_errors.join(', ')}, max decimal precision is #{MAX_PRECISION}"
                )
              end
            end

            # check that all enums have same interval
            if run_validation?(passthru, :enum_interval)
              if self[:enum].size > 1
                big_decimal_enum = self[:enum].map { |v| BigDecimal(v.to_s) }
                diff = (big_decimal_enum[1] - big_decimal_enum[0]).abs

                big_decimal_enum.each_with_index do |_value, i|
                  next if i == 0

                  new_diff = (big_decimal_enum[i] - big_decimal_enum[i - 1]).abs
                  if diff != new_diff
                    add_error_on_path(
                      errors,
                      'enum',
                      "found different interval from initial at index #{i}"
                    )
                    break
                  end
                end
              end
            end

          end

          super.merge(errors)
        end

        ###########
        # METHODS #
        ###########

        # Checks if field is valid for a locale
        #
        # @param [String,Symbol] locale
        # @return [Boolean]
        def valid_for_locale?(locale = DEFAULT_LOCALE)
          label_is_valid = super

          missing_locale = self[:enum].find do |value|
            i18n_value(value, locale).to_s.empty?
          end

          label_is_valid && !missing_locale
        end

        # get the translation for a value
        #
        # @param [number|String] value
        # @param [String,Symbol] locale
        # @return [String]
        def i18n_value(value, locale = DEFAULT_LOCALE)
          dig(:displayProperties, :i18n, :enum, locale, value.to_s)
        end

        # @retun [Integer, Float]
        def max_score
          self[:enum]&.max
        end

        # Returns the score, which is equal to the value if number
        #
        # @todo should it validate inclusion of value in enum key?
        #
        # @param [String]
        # @return [Integer, Float]
        def score_for_value(value)
          case value
          when ::Integer, ::Float
            value
          else
            nil
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
          self[:enum]&.sample
        end

      end
    end
  end
end