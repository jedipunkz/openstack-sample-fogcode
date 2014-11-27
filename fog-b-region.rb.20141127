#!/usr/bin/env ruby

require './connect.rb'
require 'yaml'

config           = YAML.load_file("./fog-b-region.yaml")
app_net_name     = config['net-app-name']
db_net_name      = config['net-db-name']
dmz_net_name     = config['net-dmz-name']

app_subnet_name  = config['subnet-app-name']
db_subnet_name   = config['subnet-db-name']

app_subnet_addr  = config['subnet-app-addr']
db_subnet_addr   = config['subnet-db-addr']

image_name       = config['image-name']
flavor_id        = config['flavor-id']
key_name         = config['key-name']
instance_lb      = config['instance-lb']
instance_web01   = config['instance-web-01']
instance_web02   = config['instance-web-02']
instance_app     = config['instance-app']
instance_db      = config['instance-db']

#floatingip       = config['floatingip']

# find first func
def find_first(resources, name)
  id_list = []
  for resource in resources.all(:name => name) do
    id_list.push(resource.id)
  end
  return id_list.shift
end

def find_sg_id(name)
  $conn.security_groups.all.each do |x|
    if x.name == name
      return x.id
    end
  end
end

# create app_net
$netconn.create_network({:name => app_net_name})
$netconn.create_subnet(find_first($netconn.networks, app_net_name),
                      app_subnet_addr, 4, {:name => app_subnet_name, :gateway_ip => 'None'})
# create db_net
$netconn.create_network({:name => db_net_name})
$netconn.create_subnet(find_first($netconn.networks, db_net_name),
                      db_subnet_addr, 4, {:name => db_subnet_name, :gateway_ip => 'None'})

# add rules to security groups
app_sg_id = find_sg_id('sg-all-from-app-net')
$conn.create_security_group_rule(app_sg_id, 'tcp', '1', '65535', '10.0.0.0/16')
$conn.create_security_group_rule(app_sg_id, 'icmp', '-1', '-1', '10.0.0.0/16')
dbs_sg_id = find_sg_id('sg-all-from-dbs-net')
$conn.create_security_group_rule(dbs_sg_id, 'tcp', '1', '65535', '10.0.0.0/16')
$conn.create_security_group_rule(dbs_sg_id, 'icmp', '-1', '-1', '10.0.0.0/16')

# create web instance
$conn.servers.create(
  :name => instance_lb,
  :flavor_ref => flavor_id.to_i,
  :image_ref => find_first($conn.images, image_name),
  :key_name => key_name,
  :availability_zone => 'az1',
  :security_groups => ['sg-all-from-console', 'sg-all-from-app-net', 'sg-web-from-internet'],
  :nics => [{:net_id => find_first($netconn.networks, dmz_net_name)},
    {:net_id => find_first($netconn.networks, app_net_name)}]
)

# create web instance
$conn.servers.create(
  :name => instance_web01,
  :flavor_ref => flavor_id.to_i,
  :image_ref => find_first($conn.images, image_name),
  :key_name => key_name,
  :availability_zone => 'az1',
  :security_groups => ['sg-all-from-console', 'sg-all-from-app-net', 'sg-web-from-internet'],
  :nics => [{:net_id => find_first($netconn.networks, dmz_net_name)},
    {:net_id => find_first($netconn.networks, app_net_name)}]
)

# create web instance
$conn.servers.create(
  :name => instance_web02,
  :flavor_ref => flavor_id.to_i,
  :image_ref => find_first($conn.images, image_name),
  :key_name => key_name,
  :availability_zone => 'az1',
  :security_groups => ['sg-all-from-console', 'sg-all-from-app-net', 'sg-web-from-internet'],
  :nics => [{:net_id => find_first($netconn.networks, dmz_net_name)},
    {:net_id => find_first($netconn.networks, app_net_name)}]
)

# create app instance
$conn.servers.create(
  :name => instance_app,
  :flavor_ref => flavor_id.to_i,
  :image_ref => find_first($conn.images, image_name),
  :key_name => key_name,
  :availability_zone => 'az1',
  :security_groups => ['sg-all-from-console', 'sg-all-from-app-net', 'sg-all-from-dbs-net'],
  :nics => [{:net_id => find_first($netconn.networks, dmz_net_name)},
    {:net_id => find_first($netconn.networks, app_net_name)},
    {:net_id => find_first($netconn.networks, db_net_name)}]
)

# create db instance
$conn.servers.create(
  :name => instance_db,
  :flavor_ref => flavor_id.to_i,
  :image_ref => find_first($conn.images, image_name),
  :key_name => key_name,
  :availability_zone => 'az1',
  :security_groups => ['sg-all-from-console', 'sg-all-from-dbs-net'],
  :nics => [{:net_id => find_first($netconn.networks, dmz_net_name)},
    {:net_id => find_first($netconn.networks, db_net_name)}]
)

# associate floatingip to web instance
#$conn.associate_address(find_first($conn.servers, instance_lb), floatingip)
