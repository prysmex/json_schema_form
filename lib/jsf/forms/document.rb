module JSF
  module Forms
    
    #
    # A document represents a hash to be validated by a JSF::Forms::Form instance.
    # It may contain two special keys (KEYWORDS) `meta` and `extras` that are out of spec with regards to `JSF::Forms::Form`,
    # so if present, they MUST be removed before being validated by a schema validator.
    #
    class Document < BaseHash
      instance_variable_set('@allow_dynamic_attributes', true)

      ROOT_KEYWORDS = ['meta', 'extras'].freeze
      EXTRAS_KEYS = ['pictures', 'score', 'failed', 'notes', 'report_ids'].freeze
      META_KEYS = ['coordinates', 'timestamp'].freeze

      EXTRAS_TEMPLATE = Proc.new do
        {
          pictures: [],
          score: nil,
          failed: nil,
          notes: nil,
          report_ids: []
        }
      end

      META_TEMPLATE = Proc.new do
        {
          coordinates: {},
          timestamp: nil,
          failed: nil
        }
      end

      # Filters keywords to return hash that can be validated against JSF::Forms::Form
      #
      # @return [Hash] self without ROOT_KEYWORDS
      def validatable_hash
        self.select{|k,v| !ROOT_KEYWORDS.include?(k) }
      end

      # Returns all keys except ROOT_KEYWORDS
      #
      # @return [Array<String>]
      def property_keys
        SuperHash::Utils.flatten_to_root(validatable_hash)
          .keys
          .map{|k| k.to_s.split('.').last}
      end

      # Recursively sets all missing keys present in 'document keys' inside 'extras' while
      # also merging values that already existed inside 'extras'
      # 
      # @return [Hash]
      # @return [void]
      def set_missing_extras
        mirror_data_structure(:extras)
      end
    
      # Recursively sets all missing keys present in 'document keys' inside 'meta' while
      # also merging values that already existed inside 'meta'
      # 
      # @return [Hash]
      # @return [void]
      def set_missing_meta
        mirror_data_structure(:meta)
      end
    
      # Iterates extras hash and yields a key value pair where:
      #   - key: name of the key
      #   - value: extras hash
      #
      # Note: at least ONE of the EXTRAS_KEYS must exist
      #
      # @param hash (used for recursion)
      # @return [void]
      def each_extras(hash = self[:extras], &block)
        hash&.each do |k,v|
          if property_keys.include?(k) #(EXTRAS_KEYS & v.keys).size == 0
            yield(k,v)
          else
            each_extras(v, &block)
          end
        end
      end
    
      # Iterates meta hash and yields a key value pair where:
      #   - key: name of the key
      #   - value: meta hash
      #
      # @param hash (used for recursion)
      # @return [void]
      def each_meta(hash = self[:meta], &block)
        hash&.each do |k,v|
          if property_keys.include?(k) #(META_KEYS & v.keys).size == 0
            yield(k,v)
          else
            each_meta(v, &block)
          end
        end
      end
    
      private
    
      # used to dry code for set_missing_extras and set_missing_meta
      #
      # @param [Symbol] keyname :extras or :meta
      # @return [void]
      def mirror_data_structure(key_name)
        SuperHash::Utils.flatten_to_root(self.to_h).reject do |k,v|
          k_s = k.to_s
          next if k_s.start_with?('extras') || k_s.start_with?('meta')
    
          hash = if key_name == :extras
            EXTRAS_TEMPLATE.call
          elsif key_name == :meta
            META_TEMPLATE.call
          end
    
          path = k_s.split('.')
          data = hash.merge(self.dig(key_name, *path) || {})
        
          SuperHash::Utils.bury(self, key_name, *path, data)
        end
      end
    
    end
  end
end