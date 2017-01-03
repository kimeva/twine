module Twine
  @@stdout = STDOUT
  @@stderr = STDERR

  def self.stdout
    @@stdout
  end

  def self.stdout=(out)
    @@stdout = out
  end

  def self.stderr
    @@stderr
  end

  def self.stderr=(err)
    @@stderr = err
  end

  class Error < StandardError
  end

  require 'twine/plugin'
  require 'twine/cli'
  require 'twine/twine_file'
  require 'twine/encoding'
  require 'twine/output_processor'
  require 'twine/placeholders'
  require 'twine/formatters'
  require 'twine/formatters/abstract'
  require 'twine/formatters/android'
  require 'twine/formatters/apple'
  require 'twine/formatters/json'
  require 'twine/runner'
  require 'twine/version'
end
