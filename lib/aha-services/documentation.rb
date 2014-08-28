module Documentation
  module ClassMethods

    #
    # Return the documentation for the service, in Markdown format.
    #
    def doc
      File.new(doc_path + '/' + doc_filename).read
    rescue Errno::ENOENT
      "No documentation for #{doc_filename}"
    end

    def doc_path
      File.expand_path("../../../docs", __FILE__)
    end
    
    def doc_filename
      "#{service_name}.md"
    end
    
  end
end