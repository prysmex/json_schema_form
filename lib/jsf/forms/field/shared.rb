# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class Shared < BaseHash

        include JSF::Forms::Field::Concerns::Base

        REF_REGEX = %r{\A#/\$defs/\w+\z}

        ###############
        # VALIDATIONS #
        ###############

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          ref_presence = run_validation?(passthru, :ref_presence)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)

          self.class.cache("#{ref_presence}#{hide_on_create}") do
            Dry::Schema.JSON(parent: super) do
              config.validate_keys = true
              if ref_presence
                required(:$ref).filled { str? & format?(REF_REGEX) }
              else
                required(:$ref).maybe { str? & format?(REF_REGEX) }
              end
              required(:displayProperties).hash do
                required(:component).value(eql?: 'shared')
                optional(:hidden).filled(:bool)
                optional(:hideOnCreate).filled(:bool) if hide_on_create
                required(:i18n).hash do
                  required(:label).hash do
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
            end
          end
        end

        ###########
        # METHODS #
        ###########

        # Gets json pointer $ref, should point to its pair (JSF::Forms::SharedRef, JSF::Forms::Form)
        # inside the form's '$defs' key
        #
        # @return [String]
        def shared_def_pointer
          dig(:$ref)
        end

        # Extracts the id from the json pointer
        #
        # @return [Integer]
        def db_id
          shared_def_pointer&.match(/\d+\z/)&.to_s&.to_i
        end

        # Update the db id in the shared_def_pointer
        #
        # @param [Integer]
        # @return [void]
        def db_id=(id)
          self[:$ref] = "#/$defs/#{JSF::Forms::Form.shared_ref_key(id)}"
        end

        # @return [JSF::Forms::SharedRef, JSF::Forms::Form]
        def shared_def
          path = shared_def_pointer&.sub('#/', '')&.split('/')&.map(&:to_sym)
          return if path.nil? || path.empty?

          find_parent do |current, _next|
            current.key?(:$defs)
          end&.dig(*path)
        end

      end
    end
  end
end