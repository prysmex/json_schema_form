# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class Signature < BaseHash

        REQUIRED = %w[name signature].freeze

        include JSF::Forms::Field::Concerns::Base
        # include JSF::Core::Type::Objectable

        set_strict_type('object')

        ###############
        # VALIDATIONS #
        ###############

        # @param passthru [Hash{Symbol => *}]
        def errors(**passthru)
          errors_hash = super

          unless REQUIRED.all? { |k| self[:required]&.include?(k) }
            add_error_on_path(
              errors_hash,
              'required',
              'signature and name must be required'
            )
          end

          errors_hash
        end

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          extras = run_validation?(passthru, :extras, optional: true)

          self.class.cache("#{hide_on_create}#{extras}") do
            Dry::Schema.JSON(parent: super) do
              before(:key_validator) do |result| # result.to_h (shallow dup)
                result.to_h.deep_dup.tap do |h|
                  if (audience = h&.dig('displayProperties', 'audience'))
                    audience.each do |v|
                      v['values'] = [] if v['values'].is_a?(::Array)
                    end
                  end
                end
              end

              required(:displayProperties).hash do
                optional(:restrictToCurrentUser).filled(:bool)
                optional(:audience).array(:hash) do
                  required(:field)
                  required(:values)
                  optional(:type)
                end
                optional(:hideOnCreate).filled(:bool) if hide_on_create
                optional(:hidden).filled(:bool)
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
                required(:sort).filled(:integer)
                required(:component).value(eql?: 'signature')
                required(:visibility).hash do
                  required(:label).filled(:bool)
                end
              end
              required(:properties).hash do
                required(:by_id).hash do
                  required(:type).value(eql?: 'number')
                end
                required(:db_identifier).hash do
                  required(:type).value(eql?: 'number')
                end
                required(:name).hash do
                  required(:type).value(eql?: 'string')
                end
                required(:signature).hash do
                  required(:type).value(eql?: 'string')
                  required(:format).value(eql?: 'uri')
                  required(:pattern).value(eql?: '^http')
                end
              end
              required(:additionalProperties).value(eql?: false)
              optional(:extra).value(:array?).array(:str?).each(included_in?: %w[reports notes pictures]) if extras
              required(:required).value(:array, min_size?: 0, max_size?: 4).each(included_in?: %w[by_id db_identifier name signature])
              required(:type)
            end
          end
        end

        ###########
        # METHODS #
        ###########

        def sample_value
          string_length = 8
          string = rand(36**string_length).to_s(36)

          {
            'db_identifier' => 2,
            'name' => string,
            'signature' => "https://picsum.photos/#{rand(10...500)}"
          }
        end

      end
    end
  end
end