module Rack
  class GridFS
    class Endpoint
      module Base
        attr_reader :db

        def initialize(options = {})
          @options = default_options.merge(options)

          @db      = @options[:db]
          @lookup  = @options[:lookup]
          @mapper  = @options[:mapper]
          @fs_name = @options[:fs_name]
        end

        def call(env)
          with_rescues do
            request = Rack::Request.new(env)
            key     = key_for_path(request.path_info)
            file    = find_file(key)

            response_for(file, request)
          end
        end

        def key_for_path(path)
          @mapper.respond_to?(:call) ? @mapper.call(path) : path
        end

        protected

        def default_options
          {
            :lookup => :id,
            :mapper => lambda { |path| %r!/(.+)!.match(path)[1] },
            :fs_name => Mongo::Grid::FSBucket::DEFAULT_ROOT
          }
        end

        def with_rescues
          bson_major_version = BSON::VERSION.split(".").first.to_i
          bson_error = bson_major_version < 5 ? BSON::ObjectId::Invalid : BSON::Error::InvalidObjectId
          rescue_connection_failure { yield }
        rescue Mongo::Error::FileNotFound, bson_error => e
          [ 404, {'Content-Type' => 'text/plain'}, ["File not found. #{e}"] ]
        rescue Mongo::Error => e
          [ 500, {'Content-Type' => 'text/plain'}, ["An error occured. #{e}"] ]
        end

        def rescue_connection_failure(max_retries=60)
          retries = 0
          begin
            yield
          rescue Mongo::Error::ConnectionPerished => e
          # Mongo::Error::ConnectionUnavailable, available >=2.19
            retries += 1
            raise e if retries > max_retries
            sleep(0.5)
            retry
          end
        end

        def response_for(file, request)
          [ 200, headers(file), file ]
        end

        def find_file(id_or_path)
          case @lookup.to_sym
          when :id
            db.fs(fs_name: @fs_name).open_download_stream(BSON::ObjectId.from_string(id_or_path))
          when :path
            path = CGI::unescape(id_or_path)
            db.fs(fs_name: @fs_name).open_download_stream_by_name(path)
          end
        end

        def headers(file)
          { 'Content-Type' => file.file_info.content_type }
        end

      end
    end
  end
end
