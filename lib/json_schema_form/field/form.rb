module JsonSchemaForm
  module Field
    class Form < ::JsonSchemaForm::Type::Object

      FORM_BUILDER_PROC = Proc.new do |obj, parent|
        case obj[:type]
        when 'string', :string
          if obj[:format] == "date-time"
            JsonSchemaForm::Field::DateInput.new(obj, parent)
          elsif !obj[:enum].nil?
            JsonSchemaForm::Field::Select.new(obj, parent)
          else
            JsonSchemaForm::Field::TextInput.new(obj, parent)
          end
        when 'number', :number, 'integer', :integer
          if obj[:displayProperties].try(:[], :useSlider)
            JsonSchemaForm::Field::Slider.new(obj, parent)
          else
            JsonSchemaForm::Field::NumberInput.new(obj, parent)
          end
        when 'boolean', :boolean
          JsonSchemaForm::Field::Switch.new(obj, parent)
        when 'array', :array
          if true#obj[:displayProperties].try(:[], :items)
            JsonSchemaForm::Field::Checkbox.new(obj, parent)
          end
        # when 'object', :object
        #   JsonSchemaForm::Field::Object.new(obj, parent)
        when 'null', :null
          if obj[:displayProperties].try(:[], :useHeader)
            JsonSchemaForm::Field::Header.new(obj, parent)
          elsif obj[:displayProperties].try(:[], :useInfo)
            JsonSchemaForm::Field::Info.new(obj, parent)
          elsif obj[:static]
            JsonSchemaForm::Field::Static.new(obj, parent)
          else
            raise StandardError.new('null field is not valid')
          end
        else
          raise StandardError.new('schema type is not valid')
        end
      end

      FORM_PROPERTIES_PROC = ->(instance, value) {
        value.transform_values do |definition|
          FORM_BUILDER_PROC.call(definition, instance)
        end
      }

      FORM_All_OF_PROC = ->(instance, value) {
        value.map do |obj|
          schema_object = JsonSchemaForm::Field::Form.new(
            obj[:then].merge(skip_required_attrs: [:type]), 
            instance
          )
          obj.merge({
            then: schema_object
          })
        end
      }

      attribute :properties, type: Types::Hash.default({}.freeze), transform: FORM_PROPERTIES_PROC
      attribute? :sortable
      attribute? :score
      attribute? :allOf, type: Types::Array.default([].freeze).of(
        Types::Hash.schema(
          if: Types::Hash,
          then: Types::Hash
        )
      ), transform: FORM_All_OF_PROC

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
        self[:properties].map{|k,v| v[:displayProperties].try(:[], :sort) }&.min || 0
      end
  
      def max_sort
        self[:properties].map{|k,v| v[:displayProperties].try(:[], :sort) }&.max || 0
      end
  
      def property_at_sort(i)
        self[:properties].find{|k,v| v[:displayProperties].try(:[], :sort) == i}
      end
  
      def verify_sort_order
        for i in 0...self[:properties].size
          return false if property_at_sort(i).blank?
        end
        true
      end
  
      def sorted_properties
        self[:properties].values.sort_by{|v| v[:displayProperties].try(:[], :sort)}
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