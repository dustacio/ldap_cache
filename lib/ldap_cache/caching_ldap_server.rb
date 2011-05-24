module LDAPCache
  class CachingLDAPServer < LDAP::Server
    def initialize(opts={})
      base_path = File.dirname(File.expand_path(__FILE__))
      schema = LDAP::Server::Schema.new
      schema.load_system
      schema.load_file(File.join(base_path, "..", "..", "schema", "core.schema"))
      schema.resolve_oids

      directory = Net::LDAP.new(opts[:upstream_directory])
      CachingDirectoryOperation.cache = opts[:cache]

      defaults = {
        :namingContexts => ['dc=example,dc=com'],
        :operation_class => CachingDirectoryOperation,
        :operation_args => [directory],
        :nodelay => true,
        :listen => 10,
        :schema => nil
      }
      opts.merge!(defaults)
      super(opts)
    end
  end
end
