#!/usr/bin/env ruby

require 'fog'

$netconn = Fog::Network.new({
    :provider            => 'openstack',                                  
    :openstack_auth_url  => 'https://region-b.geo-1.identity.hpcloudsvc.com:35357/v2.0/tokens',
    :openstack_username  => 'josug-hirai',                     
    :openstack_tenant    => 'JOSUG',                       
    :openstack_api_key   => '',           
    :openstack_region    => 'region-b.geo-1',
    :connection_options  => {}              
})

$conn = Fog::Compute.new({
    :provider            => 'openstack',   
    :openstack_auth_url  => 'https://region-b.geo-1.identity.hpcloudsvc.com:35357/v2.0/tokens',
    :openstack_username  => 'josug-hirai',                       
    :openstack_tenant    => 'JOSUG',                  
    :openstack_api_key   => '',      
    :openstack_region    => 'region-b.geo-1',
    :connection_options  => {}          
})

# $volconn = Fog::Volume.new(
#     :provider            => 'openstack',                                      # OpenStack Fog provider
#     :openstack_auth_url  => 'https://region-b.geo-1.identity.hpcloudsvc.com:35357/v2.0/tokens', # OpenStack Keystone endpoint
#     :openstack_username  => 'josug-hirai',                                  # Your OpenStack Username
#     :openstack_tenant    => 'JOSUG',                                # Your tenant id
#     :openstack_api_key   => '',                              # Your OpenStack Password
#     :openstack_region    => 'region-b.geo-1',
#     :connection_options  => {}                                                # Optional
# )

