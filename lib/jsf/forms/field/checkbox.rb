# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class Checkbox < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Arrayable
        include JSF::Forms::Field::Concerns::ResponseSettable

        RESPONSE_SET_PATH = %i[items $ref].freeze

        set_strict_type('array')

        ###############
        # VALIDATIONS #
        ###############

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          # TODO: find a way to prevent enum from being valid
          ref_presence = run_validation?(passthru, :ref_presence)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          extras = run_validation?(passthru, :extras, optional: true)
          scoring = run_validation?(passthru, :scoring, optional: true)

          Dry::Schema.JSON(parent: super) do
            required(:displayProperties).hash do
              required(:component).value(eql?: 'checkbox')
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
            required(:items).hash do
              if ref_presence
                required(:$ref).filled { str? & format?(::JSF::Forms::Field::Concerns::ResponseSettable::REF_REGEX) }
              else
                required(:$ref).maybe { str? & format?(::JSF::Forms::Field::Concerns::ResponseSettable::REF_REGEX) }
              end
            end
            required(:type)
            required(:uniqueItems)
          end
        end

        ###########
        # METHODS #
        ###########

        # Returns the maximum attainable score based on the field's ResponseSet
        #
        # @return [NilClass, Integer, Float]
        def max_score
          response_set
            &.[](:anyOf)
            &.reduce(nil) do |sum, response|
              [
                sum,
                response[:score]
              ].compact.inject(&:+)
            end
        end

        # Returns the sum of the score matching JSF::Forms::Response
        #
        # @param [Array]
        # @return [Integer, Float]
        def score_for_value(value)
          response_set
            &.[](:anyOf)
            &.select { |response| value.include? response[:const] }
            &.reduce(nil) do |sum, response|
              [
                sum,
                response[:score]
              ].compact.inject(&:+)
            end
        end

        # Checks if any of the matching JSF::Forms::Response are considered 'failed'
        #
        # @param [Array] value
        # @return [Boolean]
        def value_fails?(value)
          response_set = self.response_set
          return false if response_set.nil? || value.nil?

          !response_set[:anyOf]
            &.find do |response|
              value.include?(response[:const]) && response[:failed] == true
            end.nil?
        end

        def sample_value
          response_set = self.response_set
          return [] if response_set.nil?

          response_set[:anyOf].sample(2)

          self.response_set
            &.dig(:anyOf)
            &.sample(2)
            &.map { |o| o&.dig(:const) }
        end

      end
    end
  end
end