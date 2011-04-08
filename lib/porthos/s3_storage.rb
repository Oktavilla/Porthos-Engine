module Porthos

  mattr_accessor :s3_storage

  class S3Storage

    attr_accessor :bucket_name,
                  :access_key_id,
                  :secret_access_key

    def initialize(options)
      options.to_options.each do |key, value|
        send("#{key.to_s}=", value) if respond_to?("#{key.to_s}=")
      end
    end

    def store(source, target)
      file = bucket.objects.build(target)
      file.content = source
      file.save
    end

    def details(key)
      bucket.objects.find(key)
    end

    def destroy(key)
      file = bucket.objects.find(key)
      file ? file.destroy : false
    end

  protected

    def bucket
      @bucket ||= service.buckets.find(bucket_name).tap do |bucket|
        bucket.save(:location => 'eu') unless bucket.exists?
      end
    end

    def service
      @service ||= S3::Service.new({
        :access_key_id => access_key_id,
        :secret_access_key => secret_access_key
      })
    end

  end
end