#
# Cookbook Name:: chef_stack
# Resource:: chef_package
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
# rubocop:disable Lint/ParenthesesAsGroupedExpression

resource_name 'chef_package'

default_action :install

property :package_name, name_property: true
property :platform, default: node['platform']
property :platform_arch, default: node['architecture']
property :use_configured_repo, default: false
property :config, default: Mash.new

action :install do
  package_info = ChefStack::PackageInfo.new(
                                            new_resource.package_name,
                                            new_resource.platform,
                                            new_resource.platform_arch
                                          )
  if use_configured_repo
    package new_resource.package_name
  else
    remote_file package_info.file_name do
      source package_info.url
      checksum package_info.checksum
    end
  end

  template package_info.config_path do
    source 'config.rb.erb'
    variables({
      :config => new_resource.config
    })
  end
end
