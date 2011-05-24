Given /^I have a client connected to "([^"]*)"$/ do |ldap_url| # "
  uri = URI.parse(ldap_url)
  @client = Net::LDAP.new(:host => uri.host,
                          :port  => uri.port,
                          :base => 'ou=users,o=rackspace',
                          :auth => {
                            :method => :simple,
                            :username => 'cn=cloudsites,o=rackspace',
                            :password => '64Yn1+xZ',
                          })
  @client.encryption({ :method => :simple_tls }) if uri.scheme == 'ldaps'
end

When /^I search for "([^"]*)"$/ do |dn| # "
  @result = @client.search(:base => dn, :filter => "(cn=dusty.jones)")
end

Then /^I should get a mail set to "([^"]*)"$/ do |mail| # "
  @result && @result.first.mail.should == mail
end


Given /^my ldap server is "([^"]*)"$/ do |ldap_url| # "
  uri = URI.parse(ldap_url)
  @client = Net::LDAP.new(
                          :host => uri.host,
                          :port  => uri.port,
                          :base => 'ou=users,o=rackspace',
                          :auth => {
                            :method => :simple,
                            :username => 'PUT YOUR DN HERE',
                            :password => 'PUT YOUR PASSWORD HERE',
                          })
  @client.encryption({ :method => :simple_tls }) if uri.scheme == 'ldaps'
end

When /^I bind as "([^"]*)" with password "([^"]*)"$/ do |dn, password|
  @response = @client.bind({:method => :simple, :username => dn, :password => password})
end

Then /^I should get a response of success$/ do
  @response.should == true
end
