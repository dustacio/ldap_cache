module LDAPCache
  class FileBasedLDAPServer < LDAP::Server
    def initialize(opts={})
      base_path = File.dirname(File.expand_path(__FILE__))
      schema = LDAP::Server::Schema.new
      schema.load_system
      schema.load_file(File.join(base_path, "..", "..", "schema", "core.schema"))
      schema.resolve_oids

      directory = FileBasedDirectory.new(opts[:file])
      defaults = {
        :namingContexts => ['dc=example,dc=com'],
        :operation_class => FileBasedDirectoryOperation,
        :operation_args => [directory],
        :nodelay => true,
        :listen => 10,
#        :schema => schema
      }

      opts.merge!(defaults)
      super(opts)
    end
  end
end
