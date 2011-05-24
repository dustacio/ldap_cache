require 'spec_helper'
$stderr = StringIO.new # certificate not verified messages

# File based will listen on 3890
# Cache will listen on 3891

MEMCACHE_CACHE_URL = 'localhost:11211'

describe LDAPCache::CachingLDAPServer do
  before :each do
    @port = 3891 # The port of the caching server, not upstream directory
    @ssl_on_connect = true

    base_path = Pathname(File.dirname(File.expand_path(__FILE__)))

    @file_server = LDAPCache::FileBasedLDAPServer.new(
                                                      :port => 3890,
                                                      :file => base_path.join('..', '..', 'test', 'fixtures', 'ldapdb.yml'),
                                                      :ssl_key_file =>  base_path.join('..', '..', 'pki', 'cert.pem'),
                                                      :ssl_cert_file => base_path.join('..', '..', 'pki', 'cert.pem'),
                                                      :ssl_on_connect => @ssl_on_connect,
                                                      :namingContexts => ['dc=example,dc=com'],
                                                      :nodelay => true,
                                                      # :logger => Logger.new("/tmp/file.log"),
                                                      :listen => 10
                                                      )

    @file_server_thread = @file_server.run_tcpserver
    @cache = Memcached.new(MEMCACHE_CACHE_URL)
    @cache.flush
    @cache_server = LDAPCache::CachingLDAPServer.new(
                                                     :port => 3891,
                                                     :cache => @cache.clone,
                                                     :upstream_directory => {
                                                       :port => 3890,
                                                       :base => 'dc=example,dc=com',
                                                       :auth => {
                                                         :method => :simple,
                                                         :username => 'cn=cloudsites,dc=example,dc=com',
                                                         :password => 'secret',
                                                       },
                                                       :encryption => { :method => :simple_tls}
                                                     },
                                                     :ssl_key_file =>  base_path.join('..', '..', 'pki', 'cert.pem'),
                                                     :ssl_cert_file => base_path.join('..', '..', 'pki', 'cert.pem'),
                                                     :ssl_on_connect => @ssl_on_connect,
                                                     :namingContexts => ['dc=example,dc=com'],
                                                     :nodelay => true,
                                                     # :logger => Logger.new("/tmp/cache.log"),
                                                     :listen => 10
                                                     )
    @cache_server_thread = @cache_server.run_tcpserver
    @client = Net::LDAP.new
    @client.port = @port
    @client.encryption(:method => :simple_tls)
  end

  after :each do
    @file_server.stop if @file_server
    @cache_server.stop if @cache_server
    @file_server = nil
    @cache_server = nil
    @cache.flush if @cache
    @cache = nil
    @client = nil

    GC.start
  end

  describe "when receiving a bind request" do
    it "responds with Invalid Credentials if the password is wrong" do
      @client.auth('cn=cloudsites,dc=example,dc=com', 'notright')
      @client.bind.should be_false
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
      @client.auth('cn=cloudsites,dc=example,dc=com', 'secret')
      @client.bind
      @cache.flush
    end

    it "responds with empty results when the cn is not known" do
      res = @client.search(:filter => "(cn=unknown.person)")
      res.should be_empty
    end

    it "responds with one results when the cn is known and the scope is baseobject" do
      res = @client.search(:base => 'cn=dusty.jones,ou=users,dc=example,dc=com', :scope => Net::LDAP::SearchScope_BaseObject)
      res.should have(1).entries
    end

    it "should store the results in the cache" do
      filter = "(cn=dusty.jones)"
      base = 'ou=users,dc=example,dc=com'
      scope = Net::LDAP::SearchScope_WholeSubtree
      cache_key = "#{filter}#{base}#{scope}"

      upstream_result = @client.search(:filter => "(cn=dusty.jones)",
                                       :base => 'ou=users,dc=example,dc=com',
                                       :scope => Net::LDAP::SearchScope_WholeSubtree)
      cache_result = @cache.get(cache_key)
      upstream_result.first.dn.should == cache_result.first.dn

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
