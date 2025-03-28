require 'minitest/autorun'
require 'minitest/unit'
require "minitest/rg"
require 'shoulda/context'
require 'mocha'
require 'mocha/minitest'

require 'rack/builder'
require 'rack/mock'
require 'rack/test'

require 'rack/gridfs'

class Hash
  def except(*keys)
    rejected = Set.new(respond_to?(:convert_key) ? keys.map { |key| convert_key(key) } : keys)
    reject { |key,| rejected.include?(key) }
  end
end

module Rack
  class GridFS
    module Test
      module Methods

        def stub_mongodb_connection
          Rack::GridFS::Endpoint.any_instance.stubs(:connect!).returns(true)
        end

        def test_database_options
          { hostname: "localhost", port: 27017, database: "rack_gridfs_test", prefix: "gridfs" }
        end

        def db
          db_address = "#{test_database_options[:hostname]}:#{test_database_options[:port]}"
          @db ||= Mongo::Client.new([db_address], database: test_database_options[:database]).database
        end

        def setup_middleware(opts={})
          gridfs_opts = test_database_options.merge(opts)

          Rack::Builder.new do
            use Rack::ConditionalGet
            use Rack::GridFS, gridfs_opts
            run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["Hello, World!"]] }
          end
        end

        def setup_endpoint(opts={})
          endpoint_opts = test_database_options.except(:prefix).merge(opts)

          Rack::Builder.new do
            use Rack::ConditionalGet
            map '/gridfs' do
              run Rack::GridFS::Endpoint.new(endpoint_opts)
            end
            map '/' do
              run lambda { |env| [200, {'Content-Type' => 'text/plain'}, ["Hello, World!"]] }
            end
          end
        end

        def load_artifact_return_id(filename, content_type)
          contents = contents(filename)
          db.fs.upload_from_stream(filename, contents, content_type: content_type)
        end

        def load_artifact_return_stream(filename, content_type, path=nil)
          contents = contents(filename)
          # db.fs => Mongo::Grid::FSBucket.new(db)
          file = [path, filename].join('/')
          bucket = db.fs
          bucket.open_upload_stream(file, content_type: content_type){ |f| f.write(contents) }
          bucket.open_download_stream_by_name(file)
        end

        def contents(filename)
          ::File.read(::File.join(::File.dirname(__FILE__), 'artifacts', filename))
        end

        def assert_cache_control(cache_control)
          assert_equal_header cache_control, "Cache-Control"
        end

        def assert_equal_header(expected, header)
          assert_equal expected, last_response.headers[header]
        end
      end
    end
  end
end
