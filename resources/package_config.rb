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

resource_name :chef_package_config

default_action :render

property :product_name, String, name_property: true
property :config, [String, NilClass]

action_class do
  include ChefStackCookbook::Helpers
end

action :render do
  ensure_mixlib_install_gem_installed!
  target_config = config_file(product_name)
  return if target_config.nil?

  directory ::File.dirname(target_config) do
    recursive true
    action :create
  end

  file target_config do
    action :create
    sensitive new_resource.sensitive
    content new_resource.config
  end
end
