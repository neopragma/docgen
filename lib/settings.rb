require 'yaml'

module Settings

  def initialize
    @settings = YAML.load_file('settings.yml')
  end

  def settings name
    @settings[name]
  end

end