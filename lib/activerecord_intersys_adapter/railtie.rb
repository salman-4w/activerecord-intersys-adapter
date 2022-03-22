module ActiveRecordIntersysAdapter
  class Railtie < ::Rails::Railtie
    config.after_initialize do
      Dir["#{Rails.root}/app/models/*.rb"].sort.each do |path|
        klass = File.basename(path).sub('.rb', '').camelize.constantize
        if klass.superclass == Intersys::Serial::Object
          Rails.logger.info "Register SerialObject class for #{klass.to_s}"
        end
      end
    end
  end
end
