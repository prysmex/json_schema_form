# frozen_string_literal: true

module JSF
  module Forms
    module Field
      module Concerns

        #
        # Defines the base methods for any JSF::Forms::Field class
        # It also includes other core modules
        #
        module Base

          def self.included(base)
            # require 'dry-schema'

            base.include JSF::Core::Schemable
            base.include JSF::Validations::Validatable
            base.include JSF::Validations::DrySchemaValidatable
            base.include JSF::Forms::Field::Concerns::InstanceMethods
            base.include JSF::Forms::Field::Concerns::Conditionable
            base.include JSF::Forms::Concerns::DisplayProperties
            base.include JSF::Forms::Concerns::DocumentPath
          end

        end

        module InstanceMethods

          ###############
          # VALIDATIONS #
          ###############

          # @param passthru [Hash{Symbol => *}]
          def errors(**passthru)
            errors_hash = super

            # if run_validation?(passthru, :hidden_and_required)
            #   if self.hidden? && self.required?
            #     add_error_on_path(
            #       errors_hash,
            #       ['base'],
            #       'cannot be hidden and required'
            #     )
            #   end
            # end

            # if run_validation?(passthru, :hide_on_create_and_required)
            #   if self.hideOnCreate? && self.required?
            #     add_error_on_path(
            #       errors_hash,
            #       ['base'],
            #       'cannot be hideOnCreate and required'
            #     )
            #   end
            # end

            # validate that required array properties also have minItems
            if types == ['array'] && run_validation?(passthru, :required_array)
              min_items = self['minItems'] || 0
              if required? && min_items < 1
                add_error_on_path(
                  errors_hash,
                  ['minItems'],
                  'must be at least 1 when property is required'
                )
              elsif min_items.positive? && !required?
                add_error_on_path(
                  errors_hash,
                  ['base'],
                  'must be required when minItems exist'
                )
              end
            end

            if (
              key?('default') &&
              run_validation?(passthru, :verify_default) &&
              !JSONSchemer.schema(as_json).valid?(self['default'])
            )
              add_error_on_path(
                errors_hash,
                ['default'],
                'invalid value'
              )
            end

            errors_hash
          end

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
          def dry_schema(_passthru)
            # is_subschema = meta[:is_subschema]

            Dry::Schema.JSON do
              config.validate_keys = true
              optional(:$id).filled { str? & format?(%r{\A#/properties/(?:\w|-)+\z}) }
              # optional(:$schema).filled(:string) unless is_subschema
              optional(:title).maybe(:string)
              optional(:default)
            end
          end

          # Check if field is valid for a locale
          # The simplest case is where the label exists, but each field
          # may implement more validations
          #
          # @param [String,Symbol] locale
          # @return [Boolean]
          def valid_for_locale?(locale = DEFAULT_LOCALE)
            !i18n_label(locale).to_s.empty?
          end

          ###########
          # METHODS #
          ###########

          # Returns true if field contributes to scoring
          #
          # @return [Boolean]
          def scored?
            false
          end

          # Removes all keys that are not part of the JsonSchema spec
          #
          # @todo should this be renamed?
          #
          # @return [void]
          def legalize!
            delete(:displayProperties)
            self
          end

        end

      end
    end
  end
end