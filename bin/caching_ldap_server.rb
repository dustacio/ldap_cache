#!/usr/bin/env ruby
$:.unshift('../lib')
require 'ldap_cache'

@cache = Memcached.new("localhost:11211")
base_path = Pathname(File.dirname(File.expand_path(__FILE__)))
s = LDAPCache::CachingLDAPServer.new(
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
                                     :ssl_key_file =>  File.join(base_path, '..', 'pki', 'cert.pem'),
                                     :ssl_cert_file => File.join(base_path, '..', 'pki', 'cert.pem'),
                                     :ssl_on_connect => true,
                                     :namingContexts => ['dc=example,dc=com']
                                     )
s.run_prefork
s.join
