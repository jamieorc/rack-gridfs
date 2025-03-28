require_relative './test_helper'

class ExceptionsTest < Minitest::Test
  include Rack::Test::Methods
  include Rack::GridFS::Test::Methods

  context "Rack::GridFS Exceptions" do
    setup do
      def app
        setup_middleware(lookup: :path)
      end

      @text_file = load_artifact_return_stream('test.txt', nil)
    end

    teardown do
      db["fs.files"].delete_many
    end

    should "return a 500 if an error occurs" do
      Rack::GridFS::Endpoint.any_instance.stubs(:find_file).raises(Mongo::Error)

      get "/gridfs/anything"
      assert_equal 500, last_response.status
    end

    should "retry on connection failure" do
      Rack::GridFS::Endpoint.any_instance.stubs(:find_file).raises(Mongo::Error::ConnectionPerished).then.returns(@text_file)

      get "/gridfs/test.txt"
      assert last_response.ok?
    end
  end
end
