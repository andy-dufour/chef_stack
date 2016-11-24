#
# Cookbook Name:: chef
# Recipe:: supermarket
#
# Copyright 2016 Chef Software Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'chef::client'

supermarket_ocid = JSON.parse(::File.read('/tmp/config/supermarket.json'))
chef_supermarket node['fqdn'] do
  version :latest
  chef_oauth2_app_id supermarket_ocid['uid']
  chef_oauth2_secret supermarket_ocid['secret']
  chef_oauth2_verify_ssl false
  accept_license true
  not_if { node['tags'].include?('kitchen') }
end