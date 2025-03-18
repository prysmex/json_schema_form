# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class Select < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Forms::Field::Concerns::ResponseSettable

        # set_strict_type('string')

        RESPONSE_SET_PATH = [:$ref].freeze

        ###############
        # VALIDATIONS #
        ###############

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          ref_presence = run_validation?(passthru, :ref_presence)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          extras = run_validation?(passthru, :extras, optional: true)
          scoring = run_validation?(passthru, :scoring, optional: true)

          # TODO: find a way to prevent enum from being valid
          self.class.cache("#{ref_presence}#{hide_on_create}#{extras}#{scoring}") do
            Dry::Schema.JSON(parent: super) do
              if ref_presence
                required(:$ref).filled { str? & format?(::JSF::Forms::Field::Concerns::ResponseSettable::REF_REGEX) }
              else
                required(:$ref).maybe { str? & format?(::JSF::Forms::Field::Concerns::ResponseSettable::REF_REGEX) }
              end
              required(:displayProperties).hash do
                required(:component).value(eql?: 'select')
                optional(:disableScoring) { bool? } if scoring
                optional(:hidden).filled(:bool)
                optional(:hideOnCreate).filled(:bool) if hide_on_create
                optional(:hideUntaggedOptions).filled(:bool)
                required(:i18n).hash do
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
                optional(:responseSetFilters).value(:array?).array(:str?)
                required(:sort).filled(:integer)
                optional(:unansweredBehavior).value(included_in?: %w[disable show_all])
                required(:visibility).hash do
                  required(:label).filled(:bool)
                end
              end
              optional(:extra).value(:array?).array(:str?).each(included_in?: %w[reports notes pictures]) if extras
            end
          end
        end

        ###########
        # METHODS #
        ###########

        # @return [Integer, Float]
        def max_score
          response_set
            &.[](:anyOf)
            &.reject { |property| property[:score].nil? }
            &.max_by { |property| property[:score] }
            &.[](:score)
        end

        # Returns the score of a JSF::Forms::Response for a value
        #
        # @param [String]
        # @return [Integer, Float]
        def score_for_value(value)
          response_set
            &.[](:anyOf)
            &.find { |response| response[:const] == value }
            &.[](:score)
        end

        # Checks the JSF::Forms::Response for a value is considered 'failed'
        #
        # @param [String]
        # @return [Boolean]
        def value_fails?(value)
          response_set = self.response_set
          return false if response_set.nil?

          response_set[:anyOf]
            .find { |response| response[:const] == value }
            &.[](:failed) || false
        end

        def sample_value
          response_set
            &.dig(:anyOf)
            &.sample
            &.dig(:const)
        end

      end
    end
  end
end