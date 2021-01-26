module JsonSchemaForm
  class Form < ::JsonSchemaForm::JsonSchema::Object

    attr_reader :is_inspection

    BUILDER = Proc.new do |obj, meta, options|
      klass = case obj[:type]
      when 'string', :string
        if obj[:format] == "date-time"
          JsonSchemaForm::Field::DateInput
        elsif !obj[:responseSetId].nil? || !obj[:enum].nil? # enum is for v2.11.0 compatibility
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
          klass = JsonSchemaForm::Form
        end
      end

      raise StandardError.new('builder conditions not met') if klass.nil?

      klass.new(obj, meta, options)
    end

    FORM_RESPONSE_SETS_PROC = ->(instance, value) {
      value&.each do |id, obj|
        path = if instance&.meta&.dig(:path)
          instance.meta[:path] + [:responseSets, id]
        else
          [:responseSets, id]
        end
        value[id] = JsonSchemaForm::ResponseSet.new(obj, {
          parent: instance,
          path: path
        })
      end
    }

    attribute? :responseSets, default: ->(instance) { instance.meta[:is_subschema] ? nil : {}.freeze }, transform: FORM_RESPONSE_SETS_PROC
    attribute? :availableLocales, default: ->(instance) { instance.meta[:is_subschema] ? nil : [].freeze }

    ##################
    ###VALIDATIONS####
    ##################

    def validation_schema
      is_subschema = meta[:is_subschema]
      is_inspection = self.is_inspection
      Dry::Schema.define(parent: super) do
        config.validate_keys = true
        if !is_subschema
          required(:schemaFormVersion).value(:string)
          required(:responseSets).value(:hash)
          required(:required).value(:array?).array(:str?)
          required(:availableLocales).value(:array?).array(:str?)
          if is_inspection
            optional(:maxScore) { int? | float? | nil? }
          end
        end
      end
    end

    def schema_validation_hash
      json = super
      if !meta[:is_subschema]
        json[:responseSets]&.clear
      end
      json
    end

    def schema_errors
      errors_hash = Marshal.load(Marshal.dump(super())) #new reference
      if !meta[:is_subschema]
        self[:responseSets].each do |id, resp_set|
          resp_set_errors = resp_set.schema_errors
          unless resp_set_errors.empty?
            errors_hash[:responseSets] ||= {}
            errors_hash[:responseSets][id] = resp_set_errors
          end
        end
      end
      errors_hash
    end

    ##############
    ###METHODS####
    ##############

    def compile!
      #compile root level properties
      self[:properties]&.each do |id, definition|
        definition.compile! if definition&.respond_to?(:compile!)
      end

      #compile dynamic properties
      self.get_dynamic_forms.each{|form| form.compile!}

      #remove json schema none-compliant properties
      self.delete(:responseSets)

      self
    end

    def max_score
      # ToDo check if is_inspection 
      self[:properties].inject(nil) do |acum, (name, field_def)|
        max_score_for_path = max_score_for_path(field_def)
        if max_score_for_path.nil?
          acum
        else
          acum.to_f + max_score_for_path(field_def)
        end
      end
    end

    def max_score_for_path(field)
      conditional_fields = [JsonSchemaForm::Field::Select, JsonSchemaForm::Field::Switch, JsonSchemaForm::Field::TextInput]
  
      if conditional_fields.include? field.class
    
        posible_values = case field
        when JsonSchemaForm::Field::Select
          field.response_set[:responses]
        when JsonSchemaForm::Field::Switch
          [{value: true, score: 1}, {value: false, score: 0}]
        when JsonSchemaForm::Field::TextInput
          values = []
          field.dependent_conditions.each do |condition|
            condition_value = condition[:if][:properties].values[0]
  
            value = if condition_value[:not].present?
             'BP8;x&/dTF2Qn[RG' #some very random text
            else
              if condition_value[:const].present?
                condition_value[:const]
              elsif condition_value[:enum].present?
                condition_value[:enum][0]
              end
            end
  
            values.push({value: value, score: nil})
          end
          values
        end
    
        posible_values.map do |posible_value|
          dependent_conditions = field.dependent_conditions_for_value(posible_value[:value])
          sub_schemas_max_score = dependent_conditions.inject(nil) do |acum, condition|
            max_score = condition[:then].max_score
            if max_score.nil?
              acum
            else
              acum.to_f + max_score
            end
          end
          if sub_schemas_max_score.nil?
            posible_value[:score]
          else
            posible_value[:score].to_f + sub_schemas_max_score
          end
        end.compact.max
    
      elsif field.respond_to?(:max_score)
        field.max_score
      else
        nil
      end
    end

    def valid_for_locale?(locale = :es)
      self.merged_properties.find{|k,v| v.valid_for_locale?(locale) == false}.nil? &&
      self.response_sets.find{|k,v| v.valid_for_locale?(locale) == false}.nil?
    end

    def migrate!
      # migrate properties
      self[:properties]&.each do |id, definition|
        if definition&.respond_to?(:migrate!)
          puts 'migrating ' + definition.class.to_s.demodulize
          definition.migrate!
        end
      end
      
      #migrate dynamic forms
      self.get_dynamic_forms.each{|form| form.migrate!}

      # migrate response sets
      self[:responseSets]&.each do |id, definition|
        if definition&.respond_to?(:migrate!)
          puts 'migrating response set'
          definition.migrate!
        end
      end

      # migrate form object
      if !meta[:is_subschema]
        self[:schemaFormVersion] = '1.0.0'
      end
    end

    ##############################
    ###RESPONSE SET MANAGEMENT####
    ##############################

    # get responseSets
    def response_sets
      self[:responseSets]
    end

    # returns the response set definition with specified id
    def get_response_set(id)
      self&.dig(:responseSets, id.to_sym)
    end

    def add_response_set(id, definition)
      new_definition = definition.merge({
        id: id
      })

      response_sets_hash = {}.merge(self[:responseSets])
      response_sets_hash[id] = new_definition
      self[:responseSets] = self.symbolize_recursive(response_sets_hash)
    end

    ##########################
    ###PROPERTY MANAGEMENT####
    ##########################

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

  end
end