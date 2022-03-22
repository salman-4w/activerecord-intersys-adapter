unless Hash.method_defined? :key
  Hash.class_eval do
    alias :key :index
  end
end
