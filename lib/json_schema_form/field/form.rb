module JsonSchemaForm
  module Field
    class Form < ::JsonSchemaForm::Type::Object

      BUILDER = Proc.new do |obj, meta|
        klass = case obj[:type]
        when 'string', :string
          if obj[:format] == "date-time"
            JsonSchemaForm::Field::DateInput
          elsif !obj[:enum].nil?
            JsonSchemaForm::Field::Select
          else
            JsonSchemaForm::Field::TextInput
          end
        when 'number', :number, 'integer', :integer
          if obj&.dig(:displayProperties, :useSlider)
            JsonSchemaForm::Field::Slider
          else
            JsonSchemaForm::Field::NumberInput
          end
        when 'boolean', :boolean
          JsonSchemaForm::Field::Switch
        when 'array', :array
          if true#obj&.dig(:displayProperties, :items)
            JsonSchemaForm::Field::Checkbox
          end
        # when 'object', :object
        #   JsonSchemaForm::Field::Object
        when 'null', :null
          if obj&.dig(:displayProperties, :useHeader)
            JsonSchemaForm::Field::Header
          elsif obj&.dig(:displayProperties, :useInfo)
            JsonSchemaForm::Field::Info
          elsif obj[:static]
            JsonSchemaForm::Field::Static
          else
            raise StandardError.new('null field is not valid')
          end
        end

        #detect by other ways than 'type' property
        if klass.nil?
          if obj.has_key?(:properties)
            klass = JsonSchemaForm::Field::Form
          end
        end

        raise StandardError.new('builder conditions not met') if klass.nil?

        klass.new(obj, meta)
      end

      FORM_RESPONSE_SETS_PROC = ->(instance, value) {
        value.each do |id, obj|
          path = if instance&.meta&.dig(:path)
            instance.meta[:path].concat([:response_sets, id])
          else
           [:response_sets, id]
          end
          value[id] = JsonSchemaForm::Field::ResponseSet.new(obj, {
            parent: instance,
            path: path
          })
        end
      }

      attribute? :response_sets, default: ->(instance) { {}.freeze }, transform: FORM_RESPONSE_SETS_PROC

      def validation_schema
        is_subschema = meta[:is_subschema]
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          if !is_subschema
            required(:response_sets).value(:hash)
            required(:required).value(:array?).array(:str?)
          end
        end
      end

      def schema_validation_hash
        json = super
        if !meta[:is_subschema]
          json[:response_sets]&.clear
        end
        json
      end

      def schema_errors(is_inspection=false)
        errors_hash = Marshal.load(Marshal.dump(super())) #new reference
        if !meta[:is_subschema]
          self[:response_sets].each do |id, resp_set|
            resp_set_errors = resp_set.schema_errors(is_inspection)
            unless resp_set_errors.empty?
              errors_hash[:response_sets] ||= {}
              errors_hash[:response_sets][id] = resp_set_errors
            end
          end
        end
        errors_hash
      end

      # get response_sets
      def response_sets
        self[:response_sets]
      end

      # returns the response set definition with specified id
      def get_response_set(id)
        self&.dig(:response_sets, id.to_sym)
      end

      ####property management

      def prepend_property(id, definition)
        new_definition = {}.merge(definition)
        new_definition[:displayProperties][:sort] = -1
        add_property(id, new_definition)
        resort!
      end

      def append_property(id, definition)
        new_definition = {}.merge(definition)
        new_definition[:displayProperties][:sort] = max_sort + 1
        add_property(id, new_definition)
        resort!
      end

      def insert_property_at_index(index, id, definition)
        new_definition = {}.merge(definition)
        new_definition[:displayProperties][:sort] = index - 0.5
        add_property(id, new_definition)
        resort!
      end

      def move_property(target, id)
        p = self[:properties].find{|k,v| v.id == id}
        if p.present?
          current = p[1][:displayProperties][:sort]
          r = Range.new(*[current, target].sort)
          selected = sorted_properties.select{|k| r.include?(k[:displayProperties][:sort]) }
          if target > current
            selected.each{|k| k[:displayProperties][:sort] -= 1 }
          else
            selected.each{|k| k[:displayProperties][:sort] += 1 }
          end
          p[1][:displayProperties][:sort] = target
          resort!
        end
      end

      ###sorting###

      def min_sort
        self[:properties].map{|k,v| v&.dig(:displayProperties, :sort) }&.min || 0
      end
  
      def max_sort
        self[:properties].map{|k,v| v&.dig(:displayProperties, :sort) }&.max || 0
      end
  
      def property_at_sort(i)
        self[:properties].find{|k,v| v&.dig(:displayProperties, :sort) == i}
      end
  
      def verify_sort_order
        for i in 0...self[:properties].size
          return false if property_at_sort(i).blank?
        end
        true
      end
  
      def sorted_properties
        self[:properties].values.sort_by{|v| v&.dig(:displayProperties, :sort)}
      end
  
      def resort!
        sorted = sorted_properties
        for i in 0...self[:properties].size
          sort = [min_sort, i].max
          property = sorted[i]
          property[:displayProperties][:sort] = i
        end
      end

      ###locale###

      # def get_i18n_label
      # end

      # def translate_enum_option
      # end

      # def translate_enum_options
      # end

      # def get_true_label
      # end

      # def get_false_label
      # end

    end
  end
end