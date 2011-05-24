# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ldap_cache/version"

Gem::Specification.new do |s|
  s.name        = "ldap_cache"
  s.version     = LdapCache::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Dusty Jones"]
  s.email       = ["dusty.jones@rackspace.com"]
  # s.homepage    = "http://rubygems.org/gems/ldap_cache"
  s.summary     = %q{Caching LDAP Proxy Server}
  s.description = %q{This gem provides a proxy server, that caches results to memcache}

  # s.rubyforge_project = "ldap_cache"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency('net-ldap', '~>0.1.1')
  s.add_dependency('memcached')
  s.add_dependency('activesupport', '~>3.0.3')
  s.add_dependency('ruby-ldapserver', '~>0.3.1')
  s.add_dependency('i18n', '~>0.5.0')
  s.add_development_dependency('rspec')

end
