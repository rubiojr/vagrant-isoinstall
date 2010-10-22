require 'vagrant'

class SayHelloCommand < Vagrant::Command::Base
  register "hello", "Says hello then goodbye"

  def execute
    puts 'hello'
  end
end

module VagrantISOInstall
  class Middleware
    def initialize(app, env)
    end

    def call(env)
    end

  end
end

hello = Vagrant::Action::Builder.new do
  use VagrantISOInstall::Middleware
end

Vagrant::Action.register(:hello, hello)

