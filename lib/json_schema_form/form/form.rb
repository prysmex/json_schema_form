module JsonSchemaForm
  class Form < ::SuperHash::Hasher

    attr_reader :is_inspection

    include JsonSchemaForm::SchemaMethods::Schemable
    include JsonSchemaForm::Validations::Validatable
    include JsonSchemaForm::Validations::DrySchemaValidatable
    include JsonSchemaForm::SchemaMethods::Buildable
    include JsonSchemaForm::StrictTypes::Object

    CONDITIONAL_FIELDS = [
      JsonSchemaForm::Field::Select,
      JsonSchemaForm::Field::Switch,
      JsonSchemaForm::Field::NumberInput,
      # JsonSchemaForm::Field::TextInput
    ].freeze

    SCORABLE_FIELDS = [
      JsonSchemaForm::Field::Checkbox,
      JsonSchemaForm::Field::Slider,
      JsonSchemaForm::Field::Switch,
      JsonSchemaForm::Field::Select
    ].freeze

    SUBSCHEMA_PROC = Proc.new do |inst|
      inst.define_singleton_method(:builder) do |*args|
        JsonSchemaForm::Form::BUILDER.call(*args)
      end
    end

    BUILDER = ->(attribute, obj, meta, options) {
      
      if attribute == :responseSets #temporary for compatibility on v3.0.0 migrations
        return Hash.new(obj)
      end

      if attribute == :definitions
        # if obj.key?(:properties)
        #   return JsonSchemaForm::Form.new(obj, meta, options)
        # end
        # if obj.key?(:'$ref')
        #   return JsonSchemaForm::ComponentRef.new(obj, meta, options)
        # end
        if obj[:type] == 'string'
          return JsonSchemaForm::ResponseSet.new(obj, meta, options)
        end
      end

      #ToDo be more specific
      if [:allOf, :if, :not, :additionalProperties, :items, :definitions].include?(attribute)
        return JsonSchemaForm::Schema.new(obj, meta, options.merge(preinit_proc: SUBSCHEMA_PROC ))
      end

      if attribute == :properties && obj.key?(:$ref)
        if obj.dig(:displayProperties, :isSelect)
          return JsonSchemaForm::Field::Select.new(obj, meta, options)
        else
          return ::JsonSchemaForm::Component.new(obj, meta, options)
        end
      end

      klass = case obj[:type]
      # when 'object', :object
      #   JsonSchemaForm::Form
      when 'string', :string
        if obj[:format] == 'date-time'
          JsonSchemaForm::Field::DateInput
        elsif !obj[:responseSetId].nil? #deprecated, only for compatibility before v3.0.0
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
        JsonSchemaForm::Field::Checkbox
      when 'null', :null
        if obj&.dig(:displayProperties, :useHeader)
          JsonSchemaForm::Field::Header
        elsif obj&.dig(:displayProperties, :useInfo)
          JsonSchemaForm::Field::Info
        elsif obj[:static]
          JsonSchemaForm::Field::Static
        end
      else
        #detect by other ways than 'type' property
        if obj.has_key?(:properties)
          JsonSchemaForm::Form
        end
      end

      return klass.new(obj, meta, options) if klass

      #ToDo be more specific
      if obj.has_key?(:const) || obj.has_key?(:not) || obj.has_key?(:enum)
        return JsonSchemaForm::Schema.new(obj, meta, options.merge(preinit_proc: SUBSCHEMA_PROC ))
      end

      raise StandardError.new("builder conditions not met: (attribute: #{attribute}, obj: #{obj}, meta: #{meta})")
    }

    update_attribute :definitions, default: ->(instance) { instance.meta[:is_subschema] ? nil : {}.freeze }
    attribute? :availableLocales, default: ->(instance) { instance.meta[:is_subschema] ? nil : [].freeze }

    ##################
    ###VALIDATIONS####
    ##################

    def validation_schema
      is_subschema = meta[:is_subschema]
      is_inspection = self.is_inspection
      Dry::Schema.define(parent: super) do
        if !is_subschema
          required(:schemaFormVersion).value(:string)
          required(:required).value(:array?).array(:str?)
          required(:availableLocales).value(:array?).array(:str?)
          if is_inspection
            optional(:maxScore) { int? | float? | nil? }
          end
        end
      end
    end

    def own_errors
      errors_hash = super

      if meta[:is_subschema]
        if self.has_key?('$id')
          errors_hash['$id'] = 'id should only be present in root schemas'
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
      self.get_all_of_subschemas.each{|form| form.compile!}

      self
    end

    def max_score(&block)
      # ToDo check if is_inspection 
      self[:properties].inject(nil) do |acum, (name, field_def)|
        max_score_for_path = max_score_for_path(name, field_def, &block)
        if max_score_for_path.nil?
          acum
        else
          acum.to_f + max_score_for_path
        end
      end
    end

    def max_score_for_path(name, field, &block)

      if CONDITIONAL_FIELDS.include? field.class
    
        possible_values = case field
        when JsonSchemaForm::Field::Select
          field.response_set[:anyOf].map do |obj|
            {value: obj[:const], score: obj[:score]}
          end
        when JsonSchemaForm::Field::Switch
          [{value: true, score: 1}, {value: false, score: 0}]
        when JsonSchemaForm::Field::NumberInput
          values = []
          field.dependent_conditions.each do |condition|
            condition_value = condition[:if][:properties].values[0]

            value = if condition_value[:not].present?
               'BP8;x&/dTF2Qn[RG' #some very random text
              else
                condition_value[:const]
              end
        
            values.push({value: value, score: nil})            
          end
          values
        end
    
        possible_values&.map do |possible_value|
          dependent_conditions = field.dependent_conditions_for_value({"#{name}" => possible_value[:value]}, &block)
          sub_schemas_max_score = dependent_conditions.inject(nil) do |acum, condition|
            max_score = condition[:then]&.max_score(&block)
            if max_score.nil?
              acum
            else
              acum.to_f + max_score
            end
          end
          if sub_schemas_max_score.nil?
            possible_value[:score]
          else
            possible_value[:score].to_f + sub_schemas_max_score
          end
        end&.compact&.max
    
      elsif SCORABLE_FIELDS.include? field.class
        field.max_score
      else
        nil
      end
    end

    def valid_for_locale?(locale = :es)
      all_properties_are_valid = self.merged_properties.find do |k,v|
        !v.is_a?(JsonSchemaForm::Component) && (v.valid_for_locale?(locale) == false)
      end.nil?
      all_response_sets_are_valid = self.response_sets.find do |k,v|
        v.valid_for_locale?(locale) == false
      end.nil?
      all_properties_are_valid && all_response_sets_are_valid
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
      self.get_all_of_subschemas.each{|form| form.migrate!}

      # migrate response sets
      self[:definitions]&.each do |id, definition|
        if definition&.respond_to?(:migrate!)
          puts 'migrating response set'
          definition.migrate!
        end
      end

      #3.0.0 migrations
      if self[:schemaFormVersion] != '3.0.0'
        if !meta[:is_subschema]
          new_definitions = self[:responseSets].inject({}) do |acum, (id, definition)|
            anyOf = definition[:responses].map do |r|
              hash = {
                type: 'string',
                const: r[:value],
                displayProperties: r[:displayProperties]
              }
              if self.is_inspection
                hash.merge!({
                  enableScore: r[:enableScore],
                  score: r[:score],
                  failed: r[:failed]
                })
              end
              hash
            end
            acum[id] = {
              type: 'string',
              isResponseSet: true,
              anyOf: anyOf
            }
            acum
          end
          old_definitions = SuperHash::DeepKeysTransform.symbolize_recursive(self[:definitions].as_json)
          self.delete(:responseSets)
          self[:definitions] = old_definitions.merge(new_definitions)
        else
          self.delete(:$id)
        end
        self.delete(:additionalProperties)
      end

      # migrate form object
      if !meta[:is_subschema]
        self[:schemaFormVersion] = '3.0.0'
      end
      self
    end

    #ToDo consider else key in allOf
    def get_all_of_subschemas(levels=nil, level=0)
      return [] if levels && level >= levels
      schemas_array=[]
      self[:allOf]&.each do |condition_subschema|
        subschema = condition_subschema[:then]
        if subschema
          schemas_array.push(subschema)
          schemas_array.concat(subschema.get_all_of_subschemas(levels, level + 1))
        end
      end
      schemas_array
    end

    ###########################
    ###COMPONENT MANAGEMENT####
    ###########################

    def component_definitions
      self[:definitions].select do |k,v|
        !v.key?(:type)
      end
    end

    ##############################
    ###RESPONSE SET MANAGEMENT####
    ##############################

    # get responseSets #ToDo this can be improved
    def response_sets
      self[:definitions].select do |k,v|
        v[:type] == 'string' #v.key?('anyOf')
      end
    end

    # returns the response set definition with specified id
    def get_response_set(id)
      return nil if id.nil?
      path = id&.sub('#/', '')&.split('/')&.map(&:to_sym)
      self.dig(*path)
    end

    def add_response_set(id, definition)
      new_definitions_hash = {}.merge(self[:definitions])
      new_definitions_hash[id] = definition
      self[:definitions] = SuperHash::DeepKeysTransform.symbolize_recursive(new_definitions_hash)
    end

    ##########################
    ###PROPERTY MANAGEMENT####
    ##########################

    # get properties
    def properties
      self[:properties]
    end

    # get dynamic properties
    def dynamic_properties(levels=nil)
      get_all_of_subschemas(levels).reduce({}) do |acum, subschema|
        acum.merge(subschema.properties || {})
      end
    end

    # get own and dynamic properties
    def merged_properties(levels=nil)
      (self[:properties] || {})
        .merge(self.dynamic_properties(levels))
    end

    # returns the property JSON definition inside the properties key
    def get_property(property)
      self.dig(:properties, property.to_sym)
    end

    def get_dynamic_property(property, levels=nil)
      dynamic_properties(levels).try(:[], property.to_sym)
    end

    def get_merged_property(property, levels=nil)
      merged_properties(levels).try(:[], property.to_sym)
    end

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
