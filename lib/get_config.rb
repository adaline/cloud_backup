require 'yaml'

class GetConfig
  def self.get(file)
    YAML::load(
      File.open(
        File.expand_path(
          File.join(File.dirname(__FILE__),"../config/#{file}.yaml")
        )
      )
    )
  end
end