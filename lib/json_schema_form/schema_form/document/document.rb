module SchemaForm
  module Document
    class Document < SchemaHash

      instance_variable_set('@allow_dynamic_attributes', true)

      # Iterates extras hash and yields a key value pair where:
      #   - key: name of the key
      #   - value: extras hash
      def each_extras(hash = nil, &block)
        hash = self[:extras] if hash.nil?
        hash&.each do |k,v|
          if ([:pictures, :score, :failed, :notes, :report_ids] & v.keys).size > 0
            yield(k,v)
          else
            each_extras(v, &block)
          end
        end
      end

      # Iterates meta hash and yields a key value pair where:
      #   - key: name of the key
      #   - value: meta hash
      def each_meta(hash = nil, &block)
        hash = self[:meta] if hash.nil?
        hash&.each do |k,v|
          if ([:coordinates, :timestamp] & v.keys).size > 0
            yield(k,v)
          else
            each_meta(v, &block)
          end
        end
      end

      # Recursively sets all missing keys present in 'document keys' inside 'extras' while
      # also merging values that already existed inside 'extras'
      def set_missing_extras
        mirror_data_structure(:extras)
      end

      # Recursively sets all missing keys present in 'document keys' inside 'meta' while
      # also merging values that already existed inside 'meta'
      def set_missing_meta
        mirror_data_structure(:meta)
      end

      def property_keys
        self.keys.reject{|k| [:extras, :meta].include?(k)}
      end

      private

      # used to dry code for set_missing_extras and set_missing_meta
      def mirror_data_structure(key_name)
        SuperHash::Utils.flatten_to_root(self.to_h).reject do |k,v|
          k_s = k.to_s
          next if k_s.start_with?('extras') || k_s.start_with?('meta')
        
          path = k_s.split('.').map(&:to_sym)

          hash = if key_name == :extras
            {
              pictures: [],
              score: nil,
              failed: nil,
              notes: nil,
              report_ids: []
            }
          elsif key_name == :meta
            {
              coordinates: {},
              timestamp: nil,
              failed: nil
            }
          end

          data =  hash.merge(self.dig(key_name, *path) || {})
        
          SuperHash::Utils.bury(self, key_name, *path, data)
        end
      end
  
    end
  end
end