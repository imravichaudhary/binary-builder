require_relative 'architect/architects'
require 'fileutils'

module BinaryBuilder
  class Builder
    attr_reader :binary_name, :git_tag, :architect

    def self.build(options)
      builder = self.new(options)

      builder.set_foundation
      builder.install
      builder.tar_installed_binary
    end

    def initialize(binary_name:, git_tag:)
      @binary_name, @git_tag = binary_name, git_tag
      @architect = architect_for_binary(binary_name).new(git_tag: @git_tag)
    end

    def set_foundation
      FileUtils.rm_rf(foundation_path) if Dir.exists?(foundation_path)
      FileUtils.mkdir_p(foundation_path)

      File.open(blueprint_path, 'w') do |file|
        file.chmod 0755
        file.write architect.blueprint
      end
    end

    def install
      run!(blueprint_path)
    end

    def tar_installed_binary
      FileUtils.rm(blueprint_path)
      run!(tar_command)
      FileUtils.rm_rf(foundation_path)
    end

    private
    BINARY_ARCHITECT_MAP = {
      'node' => NodeArchitect
    }

    def architect_for_binary(binary)
      BINARY_ARCHITECT_MAP[binary]
    end

    def foundation_path
      @foundation_path ||= File.join(ENV['HOME'], '.binary-builder', "#{binary_name}-#{git_tag}-foundation")
    end

    def blueprint_path
      @blueprint_path ||= File.join(foundation_path, 'blueprint.sh')
    end

    def tarball_name
      "#{binary_name}-#{git_tag}-linux-x64.tgz"
    end

    def install_command
      blueprint_path
    end

    def tar_command
      "tar czf #{tarball_name} -C #{foundation_path} ."
    end

    def run!(command)
      system(command) || raise("Failed to run command: #{command}")
    end
  end
end