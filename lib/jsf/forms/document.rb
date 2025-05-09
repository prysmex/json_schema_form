# frozen_string_literal: true

module JSF
  module Forms

    #
    # A document represents a hash to be validated by a JSF::Forms::Form instance.
    # It may contain two special keys (KEYWORDS) `meta` and `extras` that are out of spec with regards to `JSF::Forms::Form`,
    # so if present, they MUST be removed before being validated by a schema validator.
    #
    class Document < BaseHash
      instance_variable_set(:@allow_dynamic_attributes, true)

      ROOT_KEYWORDS = %w[meta].freeze

      # Filters keywords to return hash that can be validated against JSF::Forms::Form
      #
      # @return [Document] self without ROOT_KEYWORDS
      def without_keywords
        self.select { |k, _v| !ROOT_KEYWORDS.include?(k) }
      end

      # Iterates extras hash and yields a key value pair where:
      #   - key: name of the key
      #   - value: extras hash
      #
      # @param hash (used for recursion)
      # @return [void]
      def each_extras_hash(hash = dig(:meta, :extras), &)
        yield(hash) if hash
        hash&.each_value do |value|
          case value
          when Array
            value.each do |v|
              each_extras_hash(v, &) if v.is_a? Hash
            end
          when Hash
            each_extras_hash(value, &)
          end
        end
      end

    end
  end
end