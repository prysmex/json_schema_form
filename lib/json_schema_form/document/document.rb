module JsonSchemaForm
  module Document
    class Document < ::SuperHash::Hasher

      attr_reader :has_initialized
      instance_variable_set('@allow_dynamic_attributes', true)

      def initialize(init_attributes = {}, &block)
        super
        set_missing_extras
        set_missing_meta
        @has_initialized = true
      end
  
      EXTRAS_PROC = ->(instance, obj) {
        if obj.is_a? ::Hash
          obj.each do |name, definition|
            obj[name] = ::JsonSchemaForm::Document::Extras.new(definition)
          end
        end
      }
  
      META_PROC = ->(instance, obj) {
        if obj.is_a? ::Hash
          obj.each do |name, definition|
            obj[name] = ::JsonSchemaForm::Document::Meta.new(definition)
          end
        end
      }

      def set_missing_extras
        extras = self[:extras].merge({})
        self.property_keys.each do |k|
          if !extras.key?(k)
            extras[k] = {}
          end
        end
        self[:extras] = extras
      end

      def set_missing_meta
        meta = self[:meta].merge({})
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
  
      after_set ->(attr_name, value) {
        if has_initialized && ![:extras, :meta].include?(attr_name)
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
  
      attribute? :extras, default: ->(instance) { {}.freeze }, transform: EXTRAS_PROC
      attribute? :meta, default: ->(instance) { {}.freeze }, transform: META_PROC
  
    end
  end
end