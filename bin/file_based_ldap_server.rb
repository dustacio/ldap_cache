#!/usr/bin/env ruby
$:.unshift('../lib')
require 'ldap_cache'
base_path = Pathname(File.dirname(File.expand_path(__FILE__)))


schema = LDAP::Server::Schema.new
schema.load_system
schema.load_file("/home/djones/Code/cloud_ops/nimsoft_ad/test/fixtures/custom.schema")
schema.resolve_oids

s = LDAPCache::FileBasedLDAPServer.new(
                                       :port => 6360,
                                       :ssl_key_file => base_path.join("..", "pki", "cert.pem"),
                                       :ssl_cert_file => base_path.join("..", "pki", "cert.pem"),
                                       :ssl_on_connect => true,
#                                       :file => base_path.join("..", "test", "fixtures", "ldapdb.yml"),
#                                       :namingContexts =>
                  #                                       ['dc=example,dc=com']
                                       :file => "/home/djones/Code/cloud_ops/nimsoft_ad/test/fixtures/ldapdb.yml",
                                       :namingContexts => ['dc=rscloud,dc=int'],
                                       :schema => schema
                                       )
s.run_prefork
s.join

