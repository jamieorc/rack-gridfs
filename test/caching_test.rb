require_relative './test_helper'

class CachingTest < Minitest::Test
  include Rack::Test::Methods
  include Rack::GridFS::Test::Methods

  context "Rack::GridFS::Endpoint::Caching" do
    setup do
      def app
        setup_endpoint(:lookup => :path, :expires => 1800)
      end

      @text_file = load_artifact_return_stream('test.txt', nil, path='text')
    end

    teardown do
      db["fs.files"].delete_many
    end

    should "set expires header" do
      get "/gridfs/#{@text_file.file_info.filename}"
      assert_cache_control "max-age=1800, public"
    end

    should "work for small images" do
      image_id = load_artifact_return_id('3wolfmoon.jpg', 'image/jpeg')
      # gridfile = Mongo::Grid.new(db).get(image_id)
      gridfile = db.fs.open_download_stream(image_id)
      get "/gridfs/3wolfmoon.jpg"
      assert last_response.ok?
      assert_equal 'image/jpeg', last_response.content_type
      assert_equal gridfile.file_info.upload_date.httpdate, last_response.headers["Last-Modified"]
      assert_equal gridfile.file_id.to_s, last_response.headers["Etag"]
    end

    should "return 304 when Etag matches" do
      image_id = load_artifact_return_id('3wolfmoon.jpg', 'image/jpeg')
      gridfile = db.fs.open_download_stream(image_id)
      get "/gridfs/3wolfmoon.jpg", nil, {'HTTP_IF_NONE_MATCH' => gridfile.file_id.to_s}
      assert_equal 304, last_response.status
    end

    should "return 304 when Last-Modified matches" do
      image_id = load_artifact_return_id('3wolfmoon.jpg', 'image/jpeg')
      gridfile = db.fs.open_download_stream(image_id)
      get "/gridfs/3wolfmoon.jpg", nil, {'HTTP_IF_MODIFIED_SINCE' => gridfile.file_info.upload_date.httpdate}
      assert_equal 304, last_response.status
      assert_equal gridfile.file_id.to_s, last_response.headers['Etag']
    end

  end
end
