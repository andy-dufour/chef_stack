#
# Cookbook Name:: chef_stack
# Library:: helpers
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

module ChefStackCookbook
  module Helpers

    def ctl_cmd(product)
      ensure_mixlib_install_gem_installed!
      PRODUCT_MATRIX.lookup(product).ctl_command
    end

    def config_file(product)
      ensure_mixlib_install_gem_installed!
      PRODUCT_MATRIX.lookup(product).config_file
    end

    def prefix
      (platform_family?('windows') ? 'C:/Chef/' : '/etc/chef/')
    end

    def ensurekv(config, hash)
      hash.each do |k, v|
        if config =~ /^ *#{v}.*$/
          config.sub(/^ *#{v}.*$/, "#{k} '#{v}'")
        else
          config << "\n#{k} '#{v}'"
        end
      end
      config
    end

    #
    # Ensures mixlib-install gem is installed and loaded.
    #
    def ensure_mixlib_install_gem_installed!
      node.run_state[:mixlib_install_gem_installed] ||= begin # ~FC001
        if node['chef-ingredient']['mixlib-install']['git_ref']
          install_gem_from_source(
            'https://github.com/chef/mixlib-install.git',
            node['chef-ingredient']['mixlib-install']['git_ref'],
            'mixlib-install'
          )
        else
          install_gem_from_rubygems('mixlib-install', '~> 3')
        end

        require 'mixlib/install'
        require 'mixlib/install/product'
        true
      end
    end

    def install_gem_from_rubygems(gem_name, gem_version)
      Chef::Log.debug("Installing #{gem_name} v#{gem_version} from Rubygems.org")
      chefgem = Chef::Resource::ChefGem.new(gem_name, run_context)
      chefgem.version(gem_version)
      chefgem.run_action(:install)
    end
    
  end
end
