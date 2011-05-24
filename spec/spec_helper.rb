require 'rspec'
require 'net/ldap'

$:.unshift(File.expand_path('../../lib', __FILE__))
require 'ldap_cache'

RSpec.configure do |c|
  c.formatter = :doc
end

