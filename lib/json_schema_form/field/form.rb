module JsonSchemaForm
  module Field
    class Form < ::JsonSchemaForm::Type::Object

      FORM_BUILDER_PROC = Proc.new do |obj, meta|
        case obj[:type]
        when 'string', :string
          if obj[:format] == "date-time"
            JsonSchemaForm::Field::DateInput.new(obj, meta)
          elsif !obj[:enum].nil?
            JsonSchemaForm::Field::Select.new(obj, meta)
          else
            JsonSchemaForm::Field::TextInput.new(obj, meta)
          end
        when 'number', :number, 'integer', :integer
          if obj&.dig(:displayProperties, :useSlider)
            JsonSchemaForm::Field::Slider.new(obj, meta)
          else
            JsonSchemaForm::Field::NumberInput.new(obj, meta)
          end
        when 'boolean', :boolean
          JsonSchemaForm::Field::Switch.new(obj, meta)
        when 'array', :array
          if true#obj&.dig(:displayProperties, :items)
            JsonSchemaForm::Field::Checkbox.new(obj, meta)
          end
        # when 'object', :object
        #   JsonSchemaForm::Field::Object.new(obj, meta)
        when 'null', :null
          if obj&.dig(:displayProperties, :useHeader)
            JsonSchemaForm::Field::Header.new(obj, meta)
          elsif obj&.dig(:displayProperties, :useInfo)
            JsonSchemaForm::Field::Info.new(obj, meta)
          elsif obj[:static]
            JsonSchemaForm::Field::Static.new(obj, meta)
          else
            raise StandardError.new('null field is not valid')
          end
        else
          raise StandardError.new('schema type is not valid')
        end
      end

      FORM_PROPERTIES_PROC = ->(instance, value) {
        value.transform_values do |definition|
          FORM_BUILDER_PROC.call(definition, {parent: instance})
        end
      }

      FORM_RESPONSE_SETS_PROC = ->(instance, value) {
        value.transform_values do |definition|
          JsonSchemaForm::Field::ResponseSet.new(
            definition, {parent: instance}
          )
        end
      }

      FORM_All_OF_PROC = ->(instance, value) {
        value.map do |obj|
          schema_object = JsonSchemaForm::Field::Form.new(
            obj[:then].merge(skip_required_attrs: [:type]), 
            {parent: instance, is_subschema: true}
          )
          obj.merge({
            then: schema_object
          })
        end
      }

      attribute? :properties, default: ->(instance) { {}.freeze }, transform: FORM_PROPERTIES_PROC
      attribute? :response_sets, default: ->(instance) { {}.freeze }, transform: FORM_RESPONSE_SETS_PROC
      attribute? :allOf, default: ->(instance) { [].freeze }, transform: FORM_All_OF_PROC

      def validation_schema
        is_subschema = meta[:is_subschema]
        Dry::Schema.define(parent: super) do
          config.validate_keys = true
          # optional(:sortable).filled(:bool)
          if !is_subschema
            required(:required).value(:array?).array(:str?)
          end
          # optional(:score).filled(:integer)
        end
      end

      def schema_validation_hash
        json = super
        json[:response_sets]&.clear
        json
      end

      def schema_errors
        errors_hash = super
        errors_hash = Marshal.load(Marshal.dump(super)) #new reference
        self.merged_properties.each do |name, prop|
          prop_errors = prop.schema_errors
          errors_hash[name] = prop_errors unless prop_errors.empty?
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