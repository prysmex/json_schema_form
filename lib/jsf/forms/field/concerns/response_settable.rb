# frozen_string_literal: true

module JSF
  module Forms
    module Field
      module Concerns
        module ResponseSettable

          # used for validation
          REF_REGEX = %r{\A#/\$defs/[a-z0-9\-_]+\z}

          ###############
          # VALIDATIONS #
          ###############

          # since we cannot augment the displayProperties schema, remove 'responseSetFilters' when valid
          # so it passes validations
          #
          # @param passthru [Hash{Symbol => *}] Options passed
          # @return [Dry::Schema::JSON] Schema
          def dry_schema(passthru)
            Dry::Schema.JSON(parent: super) do
              before(:key_validator) do |result| # result.to_h (shallow dup)
                result.to_h.deep_dup.tap do |h|
                  d_p = h['displayProperties']
                  d_p.delete('responseSetFilters') if d_p && d_p['responseSetFilters'].is_a?(::Array)
                end
              end
            end
          end

          # # Consider response set
          # #
          # # @param [] locale
          # # @return [Boolean]
          # def valid_for_locale?(locale = DEFAULT_LOCALE)
          #   field_is_valid = super

          #   set = self.response_set
          #   field_is_valid && (set.nil? || set.valid_for_locale?(locale))
          # end

          ###########
          # METHODS #
          ###########

          # get the key of the response set
          #
          # @return [String]
          def response_set_key
            response_set_id.sub('#/$defs/', '')
          end

          # get the response_set_id, each field class should implement its own `RESPONSE_SET_PATH`
          #
          # @return [String]
          def response_set_id
            dig(*self.class::RESPONSE_SET_PATH)
          end

          # Set the response set id, each field class should implement its own `RESPONSE_SET_PATH`
          #
          # @param id [String] id of the JSF::Forms::ResponseSet
          # @return [String]
          def response_set_id=(id)
            SuperHash::Utils.bury(self, *self.class::RESPONSE_SET_PATH, "#/$defs/#{id}")
          end

          # get the field's response set. It looks for it in the first parent with the `$defs` key
          #
          # @return [JSF::Forms::ResponseSet]
          def response_set
            path = response_set_id&.sub('#/', '')&.split('/')&.map(&:to_sym)
            return if path.nil? || path.empty?

            find_parent do |current, _next|
              current.key?(:$defs)
            end&.dig(*path)
          end

          # get the translation for a value in the field's response set
          #
          # @param [Object] value
          # @param [String,Symbol] locale
          # @return [String]
          def i18n_value(value, locale = DEFAULT_LOCALE)
            response_set
              &.get_response_from_value(value)
              &.dig(:displayProperties, :i18n, locale)
          end

          # Returns true if field contributes to scoring
          #
          # @override
          #
          # @return [Boolean]
          def scored?
            !!response_set&.scored?
          end

        end
      end
    end
  end
end