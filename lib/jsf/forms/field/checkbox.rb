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

          self.class.cache("#{ref_presence}#{hide_on_create}#{extras}#{scoring}") do
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
                  optional(:helpText).hash do
                    AVAILABLE_LOCALES.each do |locale|
                      optional(locale.to_sym).maybe(:string)
                    end
                  end
                end
                optional(:modifyWarning).filled(:string)
                optional(:notes).filled(:string)
                optional(:pictures).value(:array?).array(:str?)
                optional(:readOnly).filled(:bool)
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
              optional(:maxItems)
              optional(:minItems)
              required(:type)
              required(:uniqueItems).value(eql?: true)
            end
          end
        end

        ###########
        # METHODS #
        ###########

        # Returns the maximum attainable score based on the field's ResponseSet
        #
        # @return [NilClass, Integer, Float]
        def max_score
          sum = nil

          response_set&.[](:anyOf)&.each do |response|
            score = response[:score]
            next if score.nil?

            sum = sum.nil? ? score : sum + score
          end

          sum
        end

        # Returns the sum of the score matching JSF::Forms::Response
        #
        # @param [Array] value
        # @return [NilClass, Integer, Float]
        def score_for_value(value)
          return nil if value.nil? || value.empty?

          r_set = response_set
          return nil if r_set.nil?

          sum = nil

          # Branch iteration strategy depending on cache usage:
          # - cached lookups are O(1), so iterating selected values is faster
          # - uncached lookups are O(n), so iterating anyOf once is faster
          if JSF::Current.use_cache
            value.each do |v|
              score = r_set.get_response_from_value(v)&.[](:score)
              next if score.nil?

              sum = sum.nil? ? score : sum + score
            end
          else
            r_set[:anyOf]&.each do |response|
              next unless value.include?(response[:const])

              score = response[:score]
              next if score.nil?

              sum = sum.nil? ? score : sum + score
            end
          end

          sum
        end

        # Checks if any of the matching JSF::Forms::Response are considered 'failed'
        #
        # @param [Array] value
        # @return [Boolean]
        def value_fails?(value)
          return false if value.nil? || value.empty?

          r_set = response_set
          return false if r_set.nil?

          # Branch iteration strategy depending on cache usage:
          #   - cached lookups are O(1), so iterating selected values is faster
          #   - uncached lookups are O(n), so iterating anyOf once is faster
          if JSF::Current.use_cache
            value.any? do |v|
              r_set.get_response_from_value(v)&.[](:failed) == true
            end
          else
            r_set[:anyOf]&.any? do |response|
              value.include?(response[:const]) && response[:failed] == true
            end || false
          end
        end

        # @return [Array]
        def sample_value
          response_set = self.response_set
          return [] if response_set.nil?

          response_set[:anyOf].sample(2).map { |o| o&.dig(:const) }
        end

      end
    end
  end
end