module JsonSchemaForm
  class HashBuilder
  
    def self.build(hash={}, &block)
      instance = self.new(hash)
      instance.instance_eval(&block)
      instance.init_hash
    end
  
    attr_reader :init_hash
  
    def initialize(init_hash={})
      raise TypeError.new("first argument must be a hash, got #{init_hash.class}") unless init_hash.is_a?(Hash)
      @init_hash = init_hash
    end
  
    # Catch-all unknown methods and default them to create a new key
    def method_missing(method_name, *args, &block)
      key(method_name.to_sym, *args, &block)
    end
  
    def relay(method_name, *args)
      @init_hash.send(method_name, *args)
    end

    def relay_to(key, method, *args) #&block
      @init_hash[key].relay(method, *args) #&block
    end
  
    private
  
    # Sets a hash key
    # @param (String|Symbol) Name of the key
    # @param (Array) Can contain a Hash of attributes
    # @param (Block) An optional block which will further nest HTML
    def key(key_name, *args, &block)
      raise ArgumentError.new("only two arguments are allowed, got #{args}") if args.size > 2
  
      @init_hash[key_name] = if block_given?
        raise ArgumentError.new("can only pass one argument of options when block is present, key: #{key_name}") if args.size > 1
        options = args.first || {}
        raise TypeError 'options must be a hash' if !options.nil? && !options.is_a?(Hash)
        value = ::JsonSchemaForm::HashBuilder.build(options[:init_hash] || {}, &block)
        value = (@init_hash[key_name] || {}).merge(value) if options[:merge]
        value
      else
        options = args[1] || {}
        raise TypeError 'options must be a hash' if !options.nil? && !options.is_a?(Hash)
        value = args[0]
        raise ArgumentError.new("at least one argument is req") if args.size > 1
        args.first
      end
  
    end
  
  end
end