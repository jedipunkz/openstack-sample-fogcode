#!/usr/bin/env ruby

require './connect-a.rb'
require 'yaml'

config           = YAML.load_file("./fog-a-region.yaml")
app_net_name     = config['net-app-name']
db_net_name      = config['net-db-name']
dmz_net_name     = config['net-dmz-name']

app_subnet_name  = config['subnet-app-name']
db_subnet_name   = config['subnet-db-name']
dmz_subnet_name   = config['subnet-dmz-name']

app_subnet_addr  = config['subnet-app-addr']
db_subnet_addr   = config['subnet-db-addr']
dmz_subnet_addr   = config['subnet-dmz-addr']

image_name       = config['image-name']
flavor_id        = config['flavor-id']
key_name         = config['key-name']
instance_web     = config['instance-web']
instance_app     = config['instance-app']
instance_db      = config['instance-db']

# floatingip       = config['floatingip']

ext_router_name  = config['ext-router-name']
ext_net_name     = config['ext-net-name']

def find_first(resources, name)
  id_list = []
  for resource in resources.all(:name => name) do
    id_list.push(resource.id)
  end
  return id_list.shift
end

# create app_net
$netconn.create_network({:name => app_net_name})
$netconn.create_subnet(find_first($netconn.networks, app_net_name),
                      app_subnet_addr, 4, {:name => app_subnet_name, :gateway_ip => 'None'})
# create db_net
$netconn.create_network({:name => db_net_name})
$netconn.create_subnet(find_first($netconn.networks, db_net_name),
                      db_subnet_addr, 4, {:name => db_subnet_name, :gateway_ip => 'None'})

# create dmz_net
$netconn.create_network({:name => dmz_net_name})
$netconn.create_subnet(find_first($netconn.networks, dmz_net_name),
                      dmz_subnet_addr, 4, {:name => dmz_subnet_name})

# create router
$netconn.create_router(ext_router_name,
                      {:external_gateway_info => {:network_id => find_first($netconn.networks, ext_net_name)}})

# add interface to router
$netconn.add_router_interface(find_first($netconn.routers, ext_router_name),
                              find_first($netconn.subnets, dmz_subnet_name))

# create instance
$conn.servers.create(
  :name => instance_web,
  :flavor_ref => flavor_id.to_i,
  :image_ref => find_first($conn.images, image_name),
  :key_name => key_name,
  :availability_zone => 'az1',
  :security_groups => ['sg-all-from-console', 'sg-all-from-app-net', 'sg-web-from-internet'],
  :nics => [{:net_id => find_first($netconn.networks, dmz_net_name)},
    {:net_id => find_first($netconn.networks, app_net_name)}]
)

# create instance
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

# create instance
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

# create instance
$conn.servers.create(
  :name => instance_db,
  :flavor_ref => 102,
  :image_ref => find_first($conn.images, image_name),
  :key_name => key_name,
  :availability_zone => 'az1',
  :security_groups => ['sg-all-from-console'],
  :nics => [{:net_id => find_first($netconn.networks, dmz_net_name)}]
)



# # associate floatingip
# $conn.associate_address(find_first($conn.servers, instance_web), floatingip)
