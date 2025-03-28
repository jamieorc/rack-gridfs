# -*- encoding: utf-8 -*-
require File.expand_path("../lib/rack/gridfs/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "rack-gridfs"
  s.version     = Rack::GridFS::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jamie Orchard-Hays", "Blake Carlson", "Ches Martin"]
  s.email       = ["jamieorc@gmail.com", "blake@coin-operated.net", "ches@whiskeyandgrits.net"]
  s.homepage    = "http://github.com/skinandbones/rack-gridfs"
  s.summary     = "Serve MongoDB GridFS files from Rack"
  s.description = "Rack middleware for creating HTTP endpoints for files stored in MongoDB's GridFS"

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "rack-gridfs"

  s.add_dependency("rack", ">1", "<3")
  s.add_dependency("mongo", ">=2.14.0", "<=2.21")
  s.add_dependency("bson")
  s.add_dependency("mime-types")

  s.files        = Dir.glob("lib/**/*") + %w(LICENSE README.md Rakefile)
  s.require_path = "lib"

  s.extra_rdoc_files = [
    "CHANGES.md",
    "LICENSE",
    "README.md"
  ]
end
