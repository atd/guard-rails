module Guard
  class Rails
    class Railtie < ::Rails::Railtie
      initializer 'guard_rails.remote_pry' do
        require 'pry-remote'

        if ENV['GUARD_RAILS']
          # pry-remote does not work with pry_byebug
          # https://github.com/ranmocy/guard-rails/issues/24
          class << ::Pry
            alias start start_without_pry_byebug
          end

          # Use remote_pry instead of pry
          Object.send :prepend, Guard::Rails::Pry
        end
      end
    end
    module Pry
      def pry
        FileUtils.touch(::Rails.root.join(REMOTE_PRY_SESSION_NOTIFIER))
        remote_pry
      end
    end
  end
end
