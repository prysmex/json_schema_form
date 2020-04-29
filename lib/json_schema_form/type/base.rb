module JsonSchemaForm
  module Type

    # module Test
    #   def initialize(obj, parent=nil)
    #     deep_symbolize!(obj)
    #     super(obj)
    #   end
    # end

    class Base < Structt

      # include JsonSchemaForm::Type::Test

      property :'$id'
      property :'$schema'
      property :type
      property :title
      property :description, required: -> { _title.nil? }, message: 'is required if title is not set.'
      property :default, required: true
      property :examples

      # def key_name
      #   id&.gsub(/^(.*[\\\/])/, '')
      # end

      # def _required?
      #   if parent&.type == 'object'
      #     parent.required.include?(key_name)
      #   end
      # end

      # def validations
      #   {
      #     required: _required?
      #   }
      # end

      private
    
      def deep_symbolize!(object)
        case object
        when Hash
          object.transform_keys!(&:to_sym)
        when Array
          object.map { |val| deep_symbolize! val }
        else
          raise StandardError.new('error')
        end
      end

    end
  end
end