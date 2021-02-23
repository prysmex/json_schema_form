module JsonSchemaForm
  module Document

    # lightweight class used for storing data dynamic forms
    class Document < ::SuperHash::Hasher

      attr_reader :is_inspection
      instance_variable_set('@allow_dynamic_attributes', true)
      
      #map to class for validating attributes, defaults
      EXTRAS_PROC = ->(instance, obj, attribute) {
        if obj.is_a? ::Hash
          obj.each do |name, definition|
            obj[name] = ::JsonSchemaForm::Document::Extras.new(definition)
          end
        end
      }
      
      #map to class for validating attributes, defaults
      META_PROC = ->(instance, obj, attribute) {
        if obj.is_a? ::Hash
          obj.each do |name, definition|
            obj[name] = ::JsonSchemaForm::Document::Meta.new(definition)
          end
        end
      }

      def set_missing_extras
        extras = (self[:extras] || {}).merge({})
        self.property_keys.each do |k|
          if !extras.key?(k)
            extras[k] = {}
          end
        end
        self[:extras] = extras
      end

      def set_missing_meta
        meta = (self[:meta] || {}).merge({})
        self.property_keys.each do |k|
          if !meta.key?(k)
            meta[k] = {}
          end
        end
        self[:meta] = meta
      end

      def property_keys
        self.keys.reject{|k| [:extras, :meta].include?(k)}
      end
      
      # when a new propery is added at the root label, add a corresponding
      # hash for extras and meta
      after_set ->(attr_name, value) {
        if is_inspection && ![:extras, :meta].include?(attr_name)
          if !self[:extras]&.key?(attr_name)
            hash = {}
            hash[attr_name] = {}
            self[:extras] = (self[:extras] || {}).merge(hash)
          end
          if !self[:meta]&.key?(attr_name)
            hash = {}
            hash[attr_name] = {}
            self[:meta] = (self[:meta] || {}).merge(hash)
          end
        end
      }
  
      attribute? :extras, transform: EXTRAS_PROC
      attribute? :meta, transform: META_PROC
  
    end
  end
end