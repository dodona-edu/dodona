if defined? Rack::Cors
    Rails.configuration.middleware.insert_before 0, Rack::Cors do
        allow do
            # Allow sandbox requesting fonts
            origins [ Rails.configuration.sandbox_host ]
            resource '/assets/*.woff'
        end
    end
end