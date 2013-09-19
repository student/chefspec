if Chef::VERSION >= '11.0.0'

  module ClearResourceOrProvider
    def self.extended(klass)
      place = Object
      klass.name.split('::')[0...-1].each{|cname| place = place.const_get(cname)}
      klass.send(:define_singleton_method, :spaces){ [klass, place] }
      klass.send(:define_singleton_method, :build_from_file_without_cleaning, klass.method(:build_from_file))
      class << klass ; self ; end.send :remove_method, :build_from_file
      klass.send(:define_singleton_method, :build_from_file,
                 klass.method(:build_from_file_with_cleaning))
    end

    def self.extended(klass)
      place = Object
      klass.name.split('::')[0...-1].each{|cname| place = place.const_get(cname)}
      klass.send(:define_singleton_method, :spaces){ [klass, place] }
      class << klass
        alias_method :build_from_file_without_cleaning, :build_from_file
        alias_method :build_from_file, :build_from_file_with_cleaning
      end
    end

    def remove_existing_resource_or_provider(class_name)
      spaces.each do |space|
        opts = RUBY_VERSION < '1.9'  ? [] : [false]
        if space.const_defined?(class_name, *opts)
          old_class = space.send(:remove_const, class_name)
          space.resource_classes.delete(old_class) if space.respond_to(:resource_classes)
        end
      end
    end

    def build_from_file_with_cleaning(*args)
      cookbook_name, filename = args[0,2]
      remove_existing_resource_or_provider(convert_to_class_name(filename_to_qualified_string(cookbook_name, filename)))
      build_from_file_without_cleaning(*args)
    end
  end

  Chef::Provider::LWRPBase.extend ClearResourceOrProvider
  Chef::Resource::LWRPBase.extend ClearResourceOrProvider

end
