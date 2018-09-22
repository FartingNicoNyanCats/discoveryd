
require "kemal"
require "json"

authd_url = "http://localhost:7777"

class Error
	def initialize(reason : String)
		@reason = reason
	end
	def to_json
		{
			status: "error",
			reason: @reason
		}.to_json
	end
end
class Success
	def to_json
		{status: "success"}.to_json
	end
end

class Service
	JSON.mapping({
		name: String,
		url: String
	})

	def initialize(name, url)
		@name = name
		@url = url
	end
end

registered_services = Array(Service).new

get "/authd" do |env|
	authd_url.to_json
end

get "/services" do |env|
	registered_services.to_json
end

post "/services" do |env|
	# FIXME: check permissions.
	name = env.params.json["name"]?
	url = env.params.json["url"]?

	unless name.is_a? String
		halt env, status_code: 403, response: Error.new("Invalid or missing 'name' parameter.").to_json
	end

	unless url.is_a? String
		halt env, status_code: 403, response: Error.new("Invalid or missing 'url' parameter.").to_json
	end

	if registered_services.any? {|x| x.name == name}
		halt env, status_code: 403, response: Error.new("A service of that name is already registered.").to_json
	end

	if registered_services.any? {|x| x.url == url}
		halt env, status_code: 403, response: Error.new("A service at that URL is already registered.").to_json
	end

	registered_services.push Service.new name, url

	Success.new.to_json
end

Kemal.config.extra_options do |parser|
	parser.on "-a URL", "--authd URL", "URL of authd" do |url|
		authd_url = url
	end
end

Kemal.run 12050

