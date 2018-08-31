#
# Copyright 2018 Chef Software, Inc.
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
#

name "chef-workstation-app"
license "Apache-2.0"
skip_transitive_dependency_licensing
license_file "LICENSE"

source git: "https://github.com/chef/chef-workstation-tray"
default_version "master"

build do
  block "do_build" do
    env = with_standard_compiler_flags(with_embedded_path)
    app_version = JSON.parse(File.read(File.join(project_dir, "package.json")))["version"]
    node_tools_dir = ENV['omnibus_nodejs_dir']
    node_bin_path = windows? ? node_tools_dir : File.join(node_tools_dir, "bin")
    env['PATH'] = "#{env['PATH']}#{separator}#{node_bin_path}"

    platform_name, artifact_name = if mac_os_x?
                                     ["mac", "Chef Workstation App-#{app_version}-mac.zip"]
                                   elsif linux?
                                     ["linux", "linux-unpacked"]
                                   elsif windows?
                                     ["win", "Chef Workstation App-#{app_version}-win.zip"]
                                   end


    dist_dir = File.join(project_dir, "dist")
    installer_dir = "#{install_dir}/installers"

    artifact_path = File.join(dist_dir, artifact_name)
    mkdir installer_dir
    # Ensure no leftover artifacts from a previous build -
    # electron-builder will recreate it:
    delete dist_dir

    command "npm install", env: env
    command "npm install run-script build-#{platform_name}", env: env

    if linux?
      # For linux we're using directories - electron-builder's packageer
      # fails on RHEL6 because of a missing GLIBC version for electron-builder's
      # included compression utilities (7z, tar, etc) during build.
      # Instead, we'll manually create this archive as part of the build for linux.
      target = File.join(installer_dir, "chef-workstation-app-#{platform_name}.tar.gz")
      command "tar -f #{target} -C #{artifact_path} -cz .", env: env
    else
      target = File.join(installer_dir, "chef-workstation-app-#{platform_name}.zip")
      copy artifact_path, target
    end
  end
end
