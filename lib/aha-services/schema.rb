module Schema
  module ClassMethods
    def schema
      @schema ||= []
    end

    def string(name, options = {})
      add_to_schema :string, name, options
    end

    def password(name, options = {})
      add_to_schema :password, name, options
    end

    def boolean(name, options = {})
      add_to_schema :boolean, name, options
    end
    
    def select(name, options = {})
      add_to_schema :select, name, options
    end
    
    def callback_url(options = {})
      add_to_schema :callback_url, "callback_url", options
    end

    def install_button(options = {})
      add_to_schema :install_button, "install_button", options
    end
    
    def audit_filter(options = {})
      add_to_schema :audit_filter, "audit_filter", options
    end
    
    def oauth_button(options = {})
      add_to_schema :oauth_button, "oauth_button", options
    end

    def oauth2_button(options = {})
      add_to_schema :oauth2_button, "oauth2_button", options
    end

    def slack_button(options = {})
      add_to_schema :slack_button, "slack_button", options
    end
    
    def internal(name, options = {})
      add_to_schema :internal, name, options
    end
    
    def add_to_schema(type, name, options)
      schema << [type, name.to_sym, options]
    end
    
    # Public: get a list of attributes that are approved for logging.  Don't
    # add things like tokens or passwords here.
    #
    # Returns an Array of String attribute names.
    def white_listed
      @white_listed ||= []
    end

    def white_list(*attrs)
      attrs.each do |attr|
        white_listed << attr.to_sym
      end
    end
    
    def field_by_name(name)
      @schema.detect {|f| f[1].to_sym == name.to_sym }
    end
  end
end