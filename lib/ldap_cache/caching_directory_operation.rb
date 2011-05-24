# A caching proxy to another ldap server
# Only searches, ie READ-ONLY, are supported
# Memcache is used for a caching layer

module LDAPCache
  class CachingDirectoryOperation < LDAP::Server::Operation
    include LDAPCache::FilterOperation

    CACHE_TTL = 12 * 60 * 60

    @@cache = nil
    def self.cache= cache
      @@cache = cache.clone
    end

    def self.cache
      raise RunTimeError, "No Cache Defined" if @@cache.nil?
      @@cache
    end

    def initialize(connection, messageID, dir)
      super(connection, messageID)
      @directory = dir
      @cache = self.class.cache
    end

    def cache
      @cache.clone
    end

    def directory
      @directory.clone
    end

    # Hack to get a hash of string keys from a Net::LDAP entry
    def entry_to_hash(entry)
      return {} if entry.nil?
      entry.instance_variable_get("@myhash").stringify_keys
    end
    private :entry_to_hash

    # calculate the cache key for this search
    def cache_key(filter, base, scope)
      "#{filter}#{base}#{scope}"
    end

    def simple_bind(version, dn, password)
      result = directory.bind({:method => :simple, :username => dn, :password => password})
      code = directory.get_operation_result.code
      raise LDAP::ResultError::InvalidCredentials if result != true
    end

    def upstream_search(filter, basedn, scope)
      directory.search(:filter => filter, :base => basedn, :scope => scope)
    end

    def search(basedn, scope, deref, filter)
      basedn.downcase!
      filter_str = unparse_filter(filter)

      case scope
      when LDAP::Server::BaseObject
        net_ldap_scope = Net::LDAP::SearchScope_BaseObject
        wants_one = true
      when LDAP::Server::WholeSubtree
        net_ldap_scope = Net::LDAP::SearchScope_WholeSubtree
      when LDAP::Server::OneLevel
        net_ldap_scope = Net::LDAP::SearchScope_WholeSubtree
      end

      begin
        cache_key = cache_key(filter_str, basedn, scope)
        results = cache.get(cache_key)
      rescue Memcached::NotFound => e
        results = upstream_search(filter_str, basedn, net_ldap_scope)
        cache.set(cache_key, results, CACHE_TTL) if cache_key
        # this is null for single scoped search
        # turn off mashalling with last false
      end
      if results
        if wants_one
          entry = results.first
          send_SearchResultEntry(basedn, entry_to_hash(entry))
        else
          results.each do |entry|
            send_SearchResultEntry(entry.dn, entry_to_hash(entry))
          end
        end
      end
    end
  end
end
