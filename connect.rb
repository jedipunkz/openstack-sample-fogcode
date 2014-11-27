#!/usr/bin/env ruby

require 'fog'

$aws = Fog::Compute.new({
  :provider              => 'AWS',
  :aws_access_key_id     => '',
  :aws_secret_access_key => '',
  :region                => 'ap-northeast-1'
})

$netconn = Fog::Network.new({
    :provider            => 'openstack',                                  
    :openstack_auth_url  => 'https://region-b.geo-1.identity.hpcloudsvc.com:35357/v2.0/tokens',
    :openstack_username  => '',                     
    :openstack_tenant    => 'JOSUG',                       
    :openstack_api_key   => '',           
    :openstack_region    => 'region-b.geo-1',
    :connection_options  => {}              
})

$conn = Fog::Compute.new({
    :provider            => 'openstack',   
    :openstack_auth_url  => 'https://region-b.geo-1.identity.hpcloudsvc.com:35357/v2.0/tokens',
    :openstack_username  => '',                       
    :openstack_tenant    => 'JOSUG',                  
    :openstack_api_key   => '',      
    :openstack_region    => 'region-b.geo-1',
    :connection_options  => {}          
})

