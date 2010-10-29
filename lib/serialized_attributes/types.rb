module SerializedAttributes
  class AttributeType
    attr_reader :default
    def initialize(options = {})
      @default = options[:default]
    end

    def encode(s) s end

    def type_for(key)
      SerializedAttributes.const_get(key.to_s).new if key rescue nil
    end
  end

  class Integer < AttributeType
    def parse(input)  input.blank? ? nil : input.to_i end
  end

  class Float < AttributeType
    def parse(input)  input.blank? ? nil : input.to_f end
  end

  Fixnum = Integer

  class Boolean < AttributeType
    def parse(input) 
      input == 'true' ? true : input == 'false' ? false : input && input.respond_to?(:to_i) ? (input.to_i > 0) : input
    end
  end

  TrueClass = Boolean
  FalseClass = Boolean
  
  class String < AttributeType
    # converts unicode (\u003c) to the actual character
    # http://rishida.net/tools/conversion/
    def parse(str)
      return nil if str.nil?
      str = str.to_s
      str.gsub!(/\\u([0-9a-fA-F]{4})/) do |s| 
        int = $1.to_i(16)
        if int.zero? && s != "0000"
          s
        else
          [int].pack("U")
        end
      end
      str
    end
  end

  class Time < AttributeType
    def parse(input)
      return nil if input.blank?
      case input
        when ::Time   then input
        when ::String then ::Time.parse(input)
        else input.to_time
      end
    end
    def encode(input) input ? input.utc.xmlschema : nil end
  end


  class DateTime < AttributeType
    def parse(input)
      return nil if input.blank?
      case input
        when ::DateTime   then input
        when ::String then ::DateTime.parse(input)
        else input.to_datetime
      end
    end
    def encode(input) input ? input.utc.xmlschema : nil end
  end


  class Array < AttributeType
    def initialize(options = {})
      options[:default] ||= []  
      super
      @item_type = type_for(options[:type]) if options[:type]
      @default_type = type_for("String")
    end

    def parse(input)
      unless input.nil?
        type = @item_type || type_for(input.first.class) || @default_type
        input.map! { |item| item ? type.parse(item) : nil }
      end
    end

    def encode(input)
      unless input.nil?
        type = @item_type || type_for(input.first.class) || @default_type
        input.map! { |item| item ? type.encode(item) : nil }
      end
    end
  end

  class Hash < AttributeType
    def initialize(options = {})
      options[:default] ||= {}
      super
      @key_type = String.new
      @types    = (options[:types] || {})
      @types.keys.each do |key|
        value = @types.delete(key)
        @types[key.to_s] = type_for(value)
      end
    end

    def parse(input)
      return nil if input.nil?
      input.keys.each do |key|
        value = input.delete(key)
        key_s = @key_type.parse(key)
        type  = @types[key_s] || ( value != nil && type_for(value.class) ) || @key_type
        input[key_s] = type.parse(value)
      end
      input
    end

    def encode(input)
      return nil if input.nil?
      input.each do |key, value|
        type = @types[key] || ( value != nil && type_for(value.class) ) || @key_type
        input[key] = type.encode(value)
      end
    end
  end

  class << self
    attr_accessor :types
    def add_type(type, object = nil)
      types[type] = object
      Schema.send(:define_method, type) do |*names|
        field type, *names
      end
    end
  end
  self.types = {}
end