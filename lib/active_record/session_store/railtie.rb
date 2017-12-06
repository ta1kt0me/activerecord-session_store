require 'rails/railtie'
require 'action_dispatch/session/active_record_store'
require 'active_record/session_store/version'
require "active_record/session_store/extension/logger_silencer"

module ActiveRecord
  module SessionStore
    class Railtie < Rails::Railtie
      rake_tasks { load File.expand_path("../../../tasks/database.rake", __FILE__) }

      initializer "active_record-session_store.initialize_actiondispatch" do |_|
        ActiveSupport.on_load(:action_controller) do
          if ActiveRecord::VERSION::MAJOR == 4
            require 'action_dispatch/session/legacy_support'
            ActionDispatch::Session::ActiveRecordStore.send(:include, ActionDispatch::Session::LegacySupport)
          end
        end
      end

      initializer "active_record-session_store.initialize_activerecord" do |_|
        ActiveSupport.on_load(:active_record) do
          require 'active_record/session_store/session'
          require 'active_record/session_store/sql_bypass'

          ActionDispatch::Session::ActiveRecordStore.session_class = ActiveRecord::SessionStore::Session
          Logger.send :include, ActiveRecord::SessionStore::Extension::LoggerSilencer

          begin
            require "syslog/logger"
            Syslog::Logger.send :include, ActiveRecord::SessionStore::Extension::LoggerSilencer
          rescue LoadError; end
        end
      end
    end
  end
end
