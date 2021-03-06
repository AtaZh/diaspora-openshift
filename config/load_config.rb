require 'pathname'
require 'bundler/setup'
require 'configurate'

rails_env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'

module Rails
  def self.root
    @__root ||= Pathname.new File.expand_path('../../', __FILE__)
  end
end

require Rails.root.join 'lib', 'configuration_methods'

config_dir = Rails.root.join('config').to_s


AppConfig ||= Configurate::Settings.create do
  add_provider Configurate::Provider::Dynamic
  add_provider Configurate::Provider::Env

  unless heroku? || openshift? || rails_env == "test" || File.exists?(File.join(config_dir, "diaspora.yml"))
    $stderr.puts "FATAL: Configuration not found. Copy over diaspora.yml.example"
    $stderr.puts "       to diaspora.yml and edit it to your needs."
    exit!
  end

  add_provider Configurate::Provider::YAML,
               File.join(config_dir, 'diaspora.yml'),
               namespace: rails_env, required: false unless rails_env == 'test'
  add_provider Configurate::Provider::YAML,
               File.join(config_dir, 'diaspora.yml'),
               namespace: "configuration", required: false
  add_provider Configurate::Provider::YAML,
               File.join(config_dir, 'defaults.yml'),
               namespace: rails_env
  add_provider Configurate::Provider::YAML,
               File.join(config_dir, 'defaults.yml'),
               namespace: "defaults"

  extend Configuration::Methods

  if rails_env == "production"  &&
    (environment.certificate_authorities.nil? ||
     environment.certificate_authorities.empty? ||
     !File.file?(environment.certificate_authorities.get))
    $stderr.puts "FATAL: Diaspora doesn't know where your certificate authorities are. Please ensure they are set to a valid path in diaspora.yml"
    exit!
  end
end
