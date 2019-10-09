require 'active_support/core_ext/string'

class AhaService
  include Networking
  include Errors
  include Schema
  include Api
  include Documentation
  include Helpers
  extend Schema::ClassMethods
  extend Documentation::ClassMethods

  # Public: Aha! API client for calling back into Aha!.
  #
  # Returns an AhaApi::Client.
  attr_reader :api

  # Public: Gets the unique payload data for this Service instance.
  #
  # Returns a Hashie Mash.
  attr_reader :payload

  # Public: Gets the identifier for the Service's event.
  #
  # Returns a Symbol.
  attr_reader :event

  attr_reader :event_method

  # Public: Gets the configuration data for this Service instance.
  #
  # Returns a Hashie Mash.
  attr_reader :data

  # Public: Gets the logger instance.
  #
  # Returns a Logger.
  attr_reader :logger

  # Public: The meta configuration for the Service instance.
  #
  # Returns a Hashie Mash.
  attr_reader :meta_data

  def initialize(data = {}, payload = nil, meta_data = {})
    @data = Hashie::Mash.new(data || {})
    @meta_data = Hashie::Mash.new(meta_data || {})
    @payload = Hashie::Mash.new(payload)
    @api = @data.api_client || allocate_api_client
    @logger = @data.logger || allocate_logger
  end

  def self.default_http_options
    @@default_http_options ||= {
      :request => {:timeout => 310, :open_timeout => 25},
      :ssl => {:verify => false, :verify_depth => 5},
      :headers => {}
    }
  end

  # Returns the list of events the service responds to.
  def self.responds_to_events
    self.instance_methods.collect do |method|
      method =~ /receive_(.+)/
      $1
    end.compact.collect {|e| e.to_sym }
  end
  
  # Returns true if the service responds to the specified event.
  def self.responds_to_event(event)
    self.responds_to_events.include?(event.to_sym)
  end

  # Returns a list of the services.
  def self.service_classes
    return @service_classes if @service_classes

    subclasses = [
      AhaServices::AuditWebhook,
      AhaServices::BitbucketCommitHook,
      AhaServices::Bugzilla,
      AhaServices::Confluence,
      AhaServices::DevelopmentProxy,
      AhaServices::Flowdock,
      AhaServices::Fogbugz,
      AhaServices::GithubCommitHook,
      AhaServices::GithubIssues,
      AhaServices::GitlabIssues,
      AhaServices::GoogleHangoutsChat,
      AhaServices::HipChat,
      AhaServices::Jira,
      AhaServices::JiraConnect,
      AhaServices::MicrosoftTeams,
      AhaServices::PivotalTracker,
      AhaServices::Rally,
      AhaServices::Redmine,
      AhaServices::Salesforce,
      AhaServices::SecurityWebhook,
      AhaServices::Slack,
      AhaServices::SlackCommands,
      AhaServices::TFS,
      AhaServices::Trello,
      AhaServices::VSO,
      AhaServices::Webhooks,
      AhaServices::Zendesk,
    ]

    # Remove under development services.
    #if defined?(Rails) && !["development", "staging"].include?(Rails.env)
    #  subclasses.reject! {|s| [AhaServices::Zendesk].include?(s) }
    #end
    
    @service_classes = subclasses
  end

  def respond_to_event?
    !@event_method.nil?
  end

  def receive(event, timeout = nil)
    @event = event.to_sym

    # TODO - check to see if we have a receive_event method in any of our implementations
    # this looks like an intent that was never realized. Reduce complexity if it's not being
    # used by deleting it.
    @event_method = ["receive_#{event}", "receive_event"].detect do |method|
      respond_to?(method)
    end

    unless respond_to_event?
      logger.info("#{self.class.title} ignoring event :#{@event}")
      return
    end
    logger.info("Sending :#{@event} using #{self.class.title}")
    timeout_sec = (@data.timeout || timeout || 310).to_i
    Timeout.timeout(timeout_sec, Timeout::Error) do
      send(event_method)
    end
    self
  rescue AhaService::ConfigurationError, Errno::EHOSTUNREACH, Errno::ECONNRESET,
    SocketError, Net::ProtocolError, Faraday::Error::ConnectionFailed => err
    if !err.is_a?(AhaService::Error)
      err = ConfigurationError.new(err)
    end
    raise err
  end

  class << self
    # The official title of this Service.  This is used in any
    # user-facing documentation regarding the Service.
    def title(value = nil)
      if value
        @title = value
      else
        @title ||= begin
          hook = name.dup
          hook.sub! /.*:/, ''
          hook.underscore.humanize.capitalize.titleize
        end
      end
    end
    attr_writer :title

    # Name that identifies this Service type.  This is a
    # short string that is used to uniquely identify the service internally.
    def service_name(value = nil)
      if value
        @service_name = value
      else
        @service_name ||= begin
          hook = name.dup
          hook.sub! /.*:/, ''
          hook.underscore
        end
      end
    end
    attr_writer :service_name

    # A short description of the service that will appear in the user interface.
    def caption(value = nil, &block)
      if value
        @caption = value
      elsif block_given?
        @caption = block
      else
        @caption || ""
      end
    end
    attr_writer :caption

    def caption_display(workspace_type)
      if @caption.is_a?(Proc)
        @caption.call(workspace_type)
      else
        @caption
      end
    end
 
    # Category that service should appear in in the UI.
    def category(value = nil)
      if value
        @category = value
      else
        @category || "Development"
      end
    end
    attr_writer :category
    
    def development_proxy?
      self.service_name == "development_proxy"
    end

    def engagement_integration?
      ["google_analytics"].include?(self.service_name)
    end
  end

  def allocate_logger
    @logger = AhaLogger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @logger
  end

  def get_integration_field(integration_fields, field_name)
    return nil if integration_fields.nil?
    field = integration_fields.detect do |f|
      f.integration_id.to_s == self.data.integration_id.to_s and f.name == field_name
    end
    field && field.value
  end

end
