require "donffer/version"

require "yaml"
require "optimist"
require "active_support/inflector"

opts = Optimist::options do
  opt :file, "yaml config file name to modify", :type => :string
  opt :create_new, "Create a new file if doesn't exist", :type => :boolean, :default => false
  opt :env_prefix, "Prefix to detect list of ENV settings", :type => :string
  opt :verbose, "Tell whats going on", :type => :boolean, :default => false
end

module Donffer
  class CLI
    def initialize(opts=nil)

      filename = opts[:file]
      prefix = opts[:env_prefix]
      create_new = opts[:create_new]
      verbose = opts[:verbose]

      raise "ERR: File is mandatory. See donffer -h" if filename.nil?
      file_exists = File.exists?(filename)

      raise "ERR: #{filename} doesn't exists!" if !file_exists and create_new == false
      raise "ERR: Invalid env_prefix! env_prefix must be set!" if prefix.nil? or prefix.empty?

      data = {} 
      data = YAML.load(File.read(filename)) if file_exists

      ENV.each do |key, val|
	next if !key.start_with?(prefix)
	attr = key[prefix.length..-1]
	if verbose
	  if data[attr].nil?
            p "Adding '#{attr}': '#{val}'"
 	  elsif data[attr] != val
            p "Replacing '#{attr}': '#{data[attr]}' -> '#{val}'"
          end
	end
	
	val = val.split(",") if attr.pluralize == attr
	# TODO support objects
	
	data[attr] = val
      end
      
      File.open(filename, "w") { |file| file.write(data.to_yaml) }

    end
  end
end

if File.basename($PROGRAM_NAME) == "donffer"
  Donffer::CLI.new opts
end
