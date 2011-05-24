module LDAP
  class Server
    class Schema
      def find_attrtype(n)
        return n if n.nil? or n.is_a?(LDAP::Server::Schema::AttributeType)
        r = @attrtypes[n.to_s.downcase]
        raise LDAP::ResultError::UndefinedAttributeType, "Unknown AttributeType #{n.inspect}" unless r
        r
      end
    end
  end
end

