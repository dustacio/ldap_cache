module LDAPCache
  # Readonly ldap server, based on example 3, which supports read-only
  # operation from a yaml file

  class FileBasedDirectoryOperation < LDAP::Server::Operation
    def initialize(connection, messageID, dir)
      super(connection, messageID)
      @dir = dir
    end

    def simple_bind(version, dn, password)
      log "Bind: Version=#{version}, dn=#{dn}, password=#{password}"
      # Raise an error if you want bind to fail
      dn.downcase!
      raise LDAP::ResultError::ProtocolError, "version 3 only" if version != 3
      raise LDAP::ResultError::InappropriateAuthentication if password.to_s.empty? || dn.to_s.empty?
      raise LDAP::ResultError::InvalidCredentials unless @dir.data.key?(dn)
      log "Bind Password Check #{@dir.data[dn]['userpassword'].first} == #{password}"
      raise LDAP::ResultError::InvalidCredentials unless @dir.data[dn]['userpassword'].first == password
      log "Successful auth"
      true
    end

    def search(basedn, scope, deref, filter)
      log "Search: basedn=#{basedn.inspect}, scope=#{scope.inspect}, deref=#{deref.inspect}, filter=#{filter.inspect}\n"
      basedn.downcase!

      case scope
      when LDAP::Server::BaseObject
        # client asked for single object by DN
        @dir.update
        obj = @dir.data[basedn]
        raise LDAP::ResultError::NoSuchObject unless obj
        ok = LDAP::Server::Filter.run(filter, obj)
        $debug << "Match=#{ok.inspect}: #{obj.inspect}\n" if $debug
        send_SearchResultEntry(basedn, obj) if ok

      when LDAP::Server::WholeSubtree
        @dir.update
        @dir.data.each do |dn, av|
          $debug << "Considering #{dn}\n" if $debug
          next unless dn.index(basedn, -basedn.length)    # under basedn?
          next unless LDAP::Server::Filter.run(filter, av)  # attribute filter?
          $debug << "Sending: #{dn} -->  #{av.inspect}\n" if $debug
          send_SearchResultEntry(dn, av)
        end
      else
        raise LDAP::ResultError::UnwillingToPerform, "OneLevel not implemented"
      end
    end
  end
end
