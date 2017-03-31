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

resource_name :chef_package

default_action :install

property :product_name, String, name_property: true
property :match_checksum, [TrueClass, FalseClass], default: false
property :file_name, String
property :platform, String, default: node['platform']
property :platform_version, String, default: node['platform_version']
property :platform_arch, String, default: node['kernel']['machine']
property :package_channel, Symbol, default: 'stable'.to_sym
property :package_version, String, default: 'latest'
property :use_configured_repo, [TrueClass, FalseClass], default: false
property :package_name, String
property :use_configured_file, [TrueClass, FalseClass], default: false
property :file_source, String
property :accept_license, kind_of: [TrueClass, FalseClass], default: false
property :config, kind_of: [String, NilClass]

action_class do
  include ChefStackCookbook::Helpers
end

action :install do
  ensure_mixlib_install_gem_installed!
  if new_resource.use_configured_repo
    package new_resource.package_name do
      notifies :reconfigure, "chef_package[#{new_resource.product_name}]", :immediately
    end
  elsif new_resource.use_configured_file
    chef_file new_resource.file_name do
      source new_resource.file_source
    end
    package new_resource.product_name do
      source new_resource.file_name
      notifies :reconfigure, "chef_package[#{new_resource.product_name}]", :immediately
    end
  else
    artifact_options = {
                          product_name: new_resource.product_name,
                          channel: new_resource.package_channel,
                          product_version: new_resource.package_version,
                          platform: new_resource.platform,
                          platform_version: new_resource.platform_version,
                          architecture: new_resource.platform_arch
                        }

    artifact = Mixlib::Install.new(artifact_options).artifact_info
    cache_path = Chef::Config[:file_cache_path]
    local_artifact_path = ::File.join(cache_path, ::File.basename(artifact.url))

    remote_file local_artifact_path do
      source artifact.url
      checksum artifact.sha256
    end
    package local_artifact_path do
      provider Chef::Provider::Package::Rpm if node['platform'] == 'suse'
      notifies :reconfigure, "chef_package[#{new_resource.product_name}]", :immediately
    end
  end
end

action :reconfigure do
  if ctl_cmd(new_resource.product_name).nil?
    Chef::Log.warn "Product '#{new_resource.product_name}' does not support reconfigure."
    Chef::Log.warn 'chef_ingredient is skipping :reconfigure.'
  else
    # Render the config in case it is not rendered yet
    chef_package_config new_resource.product_name do
      action :render
      config new_resource.config
      only_if { new_resource.config }
    end

    # If accept_license is set, drop .license.accepted file so that
    # reconfigure does not prompt for license acceptance. This is
    # the backwards compatible way of accepting a Chef license.
    if new_resource.accept_license && %w(analytics manage reporting compliance).include?(new_resource.product_name)
      # The way we construct the data directory for a product, that looks
      # like /var/opt/<product_name> is to get the config file path that
      # looks like /etc/<product_name>/<product_name>.rb and do path
      # manipulation.
      product_data_dir_name = ::File.basename(::File.dirname(config_file(new_resource.product_name)))
      product_data_dir = ::File.join('/var/opt', product_data_dir_name)

      directory product_data_dir do
        recursive true
        action :create
      end

      file ::File.join(product_data_dir, '.license.accepted') do
        action :touch
      end
    end

    execute "#{new_resource.product_name}-reconfigure" do
      command "#{ctl_cmd(new_resource.product_name)} reconfigure"
    end
  end
end
