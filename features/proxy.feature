Feature: Proxy LDAP Search
  In order to centralize LDAP queries
  I want to send LDAP queries through my proxy-server

Scenario: Binding to the real server "ldaps://localhost:3890" with user "cloudsites" and password "secret"
  Given my ldap server is "ldaps://localhost:3890"
  When I bind as "cn=cloudsites,dc=example,dc=com" with password "secret"
  Then I should get a response of success

Scenario: Binding to the proxy server "ldaps://localhost:3891" with user "cloudsites" and password "secret"
  Given my ldap server is "ldaps://localhost:3890"
  When I bind as "cn=cloudsites,dc=example,dc=com" with password "secret"
  Then I should get a response of success

Scenario: Searching for cn=dusty.jones,ou=users,dc=example,dc=com in the ldap server should return a user
  Given I have a client connected to "ldaps://localhost:3890"
  When I search for "cn=dusty.jones,ou=users,dc=example,dc=com"
  Then I should get a mail set to "dusty.jones@rackspace.com"

Scenario: Searching for cn=dusty.jones,ou=users,dc=example,dc=com in the proxy ldap server should return a user
  Given I have a client connected to "ldaps://localhost:3891"
  When I search for "cn=dusty.jones,ou=users,dc=example,dc=com"
  Then I should get a mail set to "dusty.jones@rackspace.com"

