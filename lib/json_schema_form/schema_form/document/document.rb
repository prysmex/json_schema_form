module SchemaForm
  module Document
    class Document < ::SuperHash::Hasher

      instance_variable_set('@allow_dynamic_attributes', true)

      def set_missing_extras
        SuperHash::Utils.flatten_to_root(self.to_h).reject do |k,v|
          k_s = k.to_s
          next if k_s.start_with?('extras') || k_s.start_with?('meta')
        
          path = k_s.split('.').map(&:to_sym)
          data = {
            pictures: [],
            score: nil,
            failed: nil,
            notes: nil,
            report_ids: []
          }.merge(self.dig(:extras, *path) || {})
        
          SuperHash::Utils.bury(self, :extras, *path, data)
        end
      end

      def set_missing_meta
        SuperHash::Utils.flatten_to_root(self.to_h).reject do |k,v|
          k_s = k.to_s
          next if k_s.start_with?('extras') || k_s.start_with?('meta')
        
          path = k_s.split('.').map(&:to_sym)
          data =  {
            coordinates: {},
            timestamp: nil,
            failed: nil
          }.merge(self.dig(:meta, *path) || {})
        
          SuperHash::Utils.bury(self, :meta, *path, data)
        end
      end

      def property_keys
        self.keys.reject{|k| [:extras, :meta].include?(k)}
      end
  
    end
  end
end