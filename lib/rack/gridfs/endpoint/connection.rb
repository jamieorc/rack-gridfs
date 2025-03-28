require 'timeout'

module Rack
  class GridFS
    class Endpoint

      module Connection
        # NOTE Mongo 2.x has no DEFAULT_PORT defined
        DEFAULT_PORT = 27017
        def initialize(*)
          super

          @hostname, @port, @database, @username, @password =
            @options.values_at(:hostname, :port, :database, :username, :password)
        end

        def default_options
          super.merge({
            :hostname => 'localhost',
            :port     => DEFAULT_PORT
          })
        end

        def db
          @db ||= (super || connect!)
        end

        protected

        def connect!
          database = nil

          Timeout::timeout(5) do
            options = {database: @database}
            options = options.merge(user: @username, password: @password) if @username
            database = Mongo::Client.new(["#{@hostname}:#{@port}"], options).database
            # database.authenticate(@username, @password) if @username
          end

          return database
        rescue Exception => e
          raise Rack::GridFSConnectionError, "Unable to connect to the MongoDB server (#{e.to_s})"
        end
      end
    end
  end
end
