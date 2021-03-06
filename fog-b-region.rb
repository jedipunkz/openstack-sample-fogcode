#!/usr/bin/env ruby

require 'fog'
require 'yaml'

platform = ARGV[0]

$aws = Fog::Compute.new({
  :provider              => 'AWS',
  :aws_access_key_id     => '',
  :aws_secret_access_key => '',
  :region                => 'ap-northeast-1'
})

@opstnet = Fog::Network.new({
    :provider            => 'openstack',
    :openstack_auth_url  => 'https://region-b.geo-1.identity.hpcloudsvc.com:35357/v2.0/tokens',
    :openstack_username  => '',
    :openstack_tenant    => 'JOSUG',
    :openstack_api_key   => '',
    :openstack_region    => 'region-b.geo-1',
    :connection_options  => {}
})

$opst = Fog::Compute.new({
    :provider            => 'openstack',
    :openstack_auth_url  => 'https://region-b.geo-1.identity.hpcloudsvc.com:35357/v2.0/tokens',
    :openstack_username  => '',
    :openstack_tenant    => 'JOSUG',
    :openstack_api_key   => '',
    :openstack_region    => 'region-b.geo-1',
    :connection_options  => {}
})

# openstack
config               = YAML.load_file("./fog-b-region.yaml")
app_net_name         = config['net-app-name']
db_net_name          = config['net-db-name']
dmz_net_name         = config['net-dmz-name']

app_subnet_name      = config['subnet-app-name']
db_subnet_name       = config['subnet-db-name']

app_subnet_addr      = config['subnet-app-addr']
db_subnet_addr       = config['subnet-db-addr']

image_name           = config['image-name']
flavor_id            = config['flavor-id']
instance_lb          = config['instance-lb']
instance_web01       = config['instance-web-01']
instance_web02       = config['instance-web-02']
instance_app         = config['instance-app']
instance_db          = config['instance-db']

#floatingip          = config['floatingip']
sg_cidr              = config['sg-cidr']

sg_all_from_console  = config['sg-all-from-console']
sg_all_from_app_net  = config['sg-all-from-app-net']
sg_all_from_dbs_net  = config['sg-all-from-dbs-net']
sg_web_from_internet = config['sg-web-from-internet']

# aws
instance_lb_aws      = config['instance-lb-aws']
instance_web01_aws   = config['instance-web-01-aws']
instance_web02_aws   = config['instance-web-02-aws']
instance_app_aws     = config['instance-app-aws']
instance_db_aws      = config['instance-db-aws']
flavor_id_aws        = config['flavor-id-aws']
image_id_aws         = config['image-id-aws']
key_name_aws         = config['key-name-aws']
sg_aws               = config['sg-aws']


def find_first(resources, name)
  id_list = []
  for resource in resources.all(:name => name) do
    id_list.push(resource.id)
  end
  return id_list.shift
end

def find_sg_id(name)
  $opst.security_groups.all.each do |x|
    if x.name == name
      return x.id
    end
  end
end

class Cloud
  def create(cloudname, *args)
    if cloudname == 'OpenStack' then
      name = args[0]
      flavor_id = args[1]
      image_id = args[2]
      key_name = args[3]
      if args[4] == 'web' then security_groups = $sg_web
      elsif args[4] == 'app' then security_groups = $sg_app
      elsif args[4] == 'db' then security_groups = $sg_db end
      if args[5] == 'web' then nics = $nics_web
      elsif args[5] == 'app' then nics = $nics_app
      elsif args[5] == 'db' then nics = $nics_db end
      availability_zone = args[6]
      $opst.servers.create(
        :name => name,
        :flavor_ref => flavor_id.to_i,
        :image_ref => image_id,
        :key_name => key_name,
        :availability_zone => availability_zone,
        :security_groups => security_groups,
        :nics => nics
      )
    elsif cloudname == 'AWS' then
      name = args[0]
      flavor_id = args[1]
      image_id = args[2]
      key_name = args[3]
      security_groups = 'default'
      $aws.servers.create(
        :tags => {'Name' => name},
        :flavor_id => flavor_id,
        :image_id => image_id,
        :key_name => key_name,
        :groups => security_groups
      )
    end
  end
end

if platform == 'openstack' then
  # create app_net
  @opstnet.create_network({:name => app_net_name})
  @opstnet.create_subnet(find_first(@opstnet.networks, app_net_name),
                        app_subnet_addr, 4, {:name => app_subnet_name, :gateway_ip => 'none'})
  # create db_net
  @opstnet.create_network({:name => db_net_name})
  @opstnet.create_subnet(find_first(@opstnet.networks, db_net_name),
                        db_subnet_addr, 4, {:name => db_subnet_name, :gateway_ip => 'none'})

  # # add rules to security groups
  app_sg_id = find_sg_id('sg-all-from-app-net')
  $opst.create_security_group_rule(app_sg_id, 'tcp', '1', '65535', sg_cidr)
  $opst.create_security_group_rule(app_sg_id, 'icmp', '-1', '-1', sg_cidr)
  dbs_sg_id = find_sg_id('sg-all-from-dbs-net')
  $opst.create_security_group_rule(dbs_sg_id, 'tcp', '1', '65535', sg_cidr)
  $opst.create_security_group_rule(dbs_sg_id, 'icmp', '-1', '-1', sg_cidr)

  $sg_web = [sg_all_from_console, sg_all_from_app_net, sg_web_from_internet]
  $sg_app = [sg_all_from_console, sg_all_from_app_net, sg_all_from_dbs_net]
  $sg_db  = [sg_all_from_console, sg_all_from_dbs_net]
  $nics_web = [{:net_id => find_first(@opstnet.networks, dmz_net_name)},
            {:net_id => find_first(@opstnet.networks, app_net_name)}]
  $nics_app = [{:net_id => find_first(@opstnet.networks, dmz_net_name)},
            {:net_id => find_first(@opstnet.networks, app_net_name)},
            {:net_id => find_first(@opstnet.networks, db_net_name)}]
  $nics_db  = [{:net_id => find_first(@opstnet.networks, dmz_net_name)},
            {:net_id => find_first(@opstnet.networks, db_net_name)}]

  # create web instance
  Cloud.new().create('OpenStack', instance_lb, flavor_id, find_first($opst.images, image_name), 'hpwork01_key', 'web', 'web', 'az1')
  Cloud.new().create('OpenStack', instance_web01, flavor_id, find_first($opst.images, image_name), 'hpwork01_key', 'web', 'web', 'az1')
  Cloud.new().create('OpenStack', instance_web02, flavor_id, find_first($opst.images, image_name), 'hpwork01_key', 'web', 'web', 'az1')
  Cloud.new().create('OpenStack', instance_app, flavor_id, find_first($opst.images, image_name), 'hpwork01_key', 'app', 'app', 'az1')
  Cloud.new().create('OpenStack', instance_db, flavor_id, find_first($opst.images, image_name), 'hpwork01_key', 'db', 'db', 'az1')
  # associate floating ip
  #$opst.associate_address(find_first($opst.servers, instance_lb), floatingip)
elsif platform == 'aws' then
  Cloud.new().create('AWS', instance_lb_aws, flavor_id_aws, image_id_aws, key_name_aws, sg_aws)
  Cloud.new().create('AWS', instance_web01_aws, flavor_id_aws, image_id_aws, key_name_aws, sg_aws)
  Cloud.new().create('AWS', instance_web02_aws, flavor_id_aws, image_id_aws, key_name_aws, sg_aws)
  Cloud.new().create('AWS', instance_app_aws, flavor_id_aws, image_id_aws, key_name_aws, sg_aws)
  Cloud.new().create('AWS', instance_db_aws, flavor_id_aws, image_id_aws, key_name_aws, sg_aws)
else
  p "platform must be 'openstack' or 'aws'."
  exit 1
end
