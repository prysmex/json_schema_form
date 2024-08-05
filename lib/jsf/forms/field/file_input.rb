# frozen_string_literal: true

module JSF
  module Forms
    module Field
      class FileInput < BaseHash

        include JSF::Forms::Field::Concerns::Base
        include JSF::Core::Type::Arrayable

        PATTERN_ANY = '^http.+\.?(?:)$'
        PATTERN_PDF = '^http.+\.?(?:pdf)$'
        PATTERN_IMAGES = '^http.+\.?(?:heic|heif|jpeg|jpg|png)$'
        PATTERNS = [PATTERN_ANY, PATTERN_PDF, PATTERN_IMAGES].freeze

        # PATTERN_REGEX = /^\^http\.\+\\\.\?\(\?:(?:\w*(?<=\w)\|?(?=\w)\w*)*\)\$/.freeze

        set_strict_type('array')

        ###############
        # VALIDATIONS #
        ###############

        # @param passthru [Hash{Symbol => *}] Options passed
        # @return [Dry::Schema::JSON] Schema
        def dry_schema(passthru)
          hide_on_create = run_validation?(passthru, :hideOnCreate, optional: true)
          extras = run_validation?(passthru, :extras, optional: true)

          self.class.cache("#{hide_on_create}#{extras}") do
            Dry::Schema.JSON(parent: super) do
              required(:displayProperties).hash do
                required(:component).value(eql?: 'file_input')
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
              optional(:extra).value(:array?).array(:str?).each(included_in?: %w[reports notes pictures]) if extras
              required(:items).hash do
                required(:format).value(eql?: 'uri')
                required(:type).value(eql?: 'string')
                required(:pattern).value(included_in?: PATTERNS) # format?: PATTERN_REGEX
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

        def sample_value
          range = (0..rand(0..2))
          range.map { "https://picsum.photos/#{rand(10...1000)}" }.uniq
        end

        def migrate!
          self['items']['pattern'] = case delete('contentMediaType')
          when '.pdf'
            PATTERN_PDF
          when String
            PATTERN_IMAGES
          else
            PATTERN_ANY
          end
        end

      end
    end
  end
end