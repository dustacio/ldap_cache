require 'spec_helper'
$stderr = StringIO.new # certificate not verified messages

# File based will listen on 3890
# Cache will listen on 3891

describe LDAPCache::FileBasedLDAPServer do
  before :each do
    @port = 3890

    base_path = File.dirname(File.expand_path(__FILE__))
    @server = LDAPCache::FileBasedLDAPServer.new(
                                             :port => @port,
                                             :file => File.join(base_path, '..', '..', 'test', 'fixtures', 'ldapdb.yml'),
                                             :ssl_key_file =>  File.join(base_path, '..', '..', 'pki', 'cert.pem'),
                                             :ssl_cert_file => File.join(base_path, '..', '..', 'pki', 'cert.pem'),
                                             :ssl_on_connect => true,
                                             :namingContexts => ['dc=example,dc=com']
                                             )
    @server.run_tcpserver

  end

  after :each do
    @server.stop if @server
  end

  describe "when receiving a bind request" do
    before :each do
      @client = Net::LDAP.new
      @client.port = @port
      @client.encryption(:method => :simple_tls)
    end

#    Net LDAP Doesn't Handle this case properly    
#    it "responds with Inappropriate Authentication for anonymous bind request" do
#      @client.bind.should be_false
#      @client.get_operation_result.code.should equal(49)
#    end

    it "responds with Invalid Credentials if the password is wrong" do
      @client.auth('cn=cloudsites,dc=example,dc=com', 'notright')
      @client.bind.should be_false
      @client.get_operation_result.code.should equal(49)
    end

    it "responds with Invalid Credentials if the user is unknown" do
      @client.auth('cn=nobody,dc=example,dc=com', 'notright')
      @client.bind.should be_false
      @client.get_operation_result.code.should equal(49)
    end

    it "responds affirmatively if the username and password are correct" do
      @client.auth('cn=cloudsites,dc=example,dc=com', 'secret')
      @client.bind.should be_true
    end
  end

  describe "when receiving a search request" do
    before :each do
      @client = Net::LDAP.new
      @client.port = @port
      @client.encryption(:method => :simple_tls)
      @client.auth('cn=cloudsites,dc=example,dc=com', 'secret')
      @client.bind
    end

    it "responds with empty results when the cn is not known" do
      res = @client.search(:filter => "(cn=unknown.person)")
      res.should be_empty
    end

    it "responds with one results when the cn is known and the scope is baseobject" do
      res = @client.search(:base => 'cn=dusty.jones,ou=users,dc=example,dc=com', :scope => Net::LDAP::SearchScope_BaseObject)
      res.should have(1).entries
    end

    it "responds with one results when the cn is known and the scope is subtree" do
      res = @client.search(:filter => "(cn=dusty.jones)",
                           :base => 'ou=users,dc=example,dc=com',
                           :scope => Net::LDAP::SearchScope_WholeSubtree)
      res.should have(1).entries
    end

    it "responds with 3 results when the cn is *" do
      res = @client.search(:filter => "(cn=*)",
                           :base => 'ou=users,dc=example,dc=com',
                           :scope => Net::LDAP::SearchScope_WholeSubtree)
      res.should have(3).entries
    end
  end
end
