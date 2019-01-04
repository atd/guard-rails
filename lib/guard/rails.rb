require 'guard/compat/plugin'
require 'guard/watcher'

module Guard
  class Rails < Plugin
    require 'guard/rails/runner'
    require 'guard/rails/railtie' if defined? ::Rails::Railtie

    attr_reader :options, :runner

    DEFAULT_OPTIONS = {
      CLI: nil,
      daemon: false,
      debugger: false,
      environment: 'development',
      force_run: false,
      pid_file: nil, # construct the filename based on options[:environment] on runtime
      host: "localhost",
      port: 3000,
      server: nil, # specified by rails
      start_on_start: true,
      timeout: 30,
      zeus_plan: 'server',
      zeus: false,
    }

    REMOTE_PRY_SESSION_NOTIFIER = '.guard-rails-pry-session'

    def initialize(options = {})
      options[:watchers] |= [remote_pry_session_watcher]

      super

      @options = DEFAULT_OPTIONS.merge(options)

      @runner = Runner.new(@options)
    end

    def start
      UI.info "[Guard::Rails] will start #{options[:server] || "the default web server"} on port #{options[:port]} in #{options[:environment]}."
      reload("start") if options[:start_on_start]
    end

    def reload(action = "restart")
      title = "#{action.capitalize}ing Rails..."
      UI.info title
      Notifier.notify("Rails #{action}ing on port #{options[:port]} in #{options[:environment]}...", title: title, image: :pending)
      if runner.restart
        UI.info "Rails #{action}ed, pid #{runner.pid}"
        Notifier.notify("Rails #{action}ed on port #{options[:port]}.", title: "Rails #{action}ed!", image: :success)
      else
        UI.info "Rails NOT #{action}ed, check your log files."
        Notifier.notify("Rails NOT #{action}ed, check your log files.", title: "Rails NOT #{action}ed!", image: :failed)
      end
    end

    def stop
      Notifier.notify("Until next time...", title: "Rails shutting down.", image: :pending)
      runner.stop
    end

    def run_on_changes(original_paths)
      paths = original_paths.dup

      if paths.delete(REMOTE_PRY_SESSION_NOTIFIER)
        system('pry-remote')
      else
        reload
      end
    end

    alias :run_on_change :run_on_changes

    private

    def remote_pry_session_watcher
      Watcher.new REMOTE_PRY_SESSION_NOTIFIER
    end
  end
end
