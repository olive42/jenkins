#
# Cookbook Name:: jenkins
# HWRP:: credentials_secret_file
#
# Author:: Dmitry Polyanitsa <d.polyanitsa@criteo.com>
#
# Copyright 2016, Criteo
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

require_relative 'credentials'
require_relative '_params_validate'

class Chef
  class Resource::JenkinsSecretFileCredentials < Resource::JenkinsCredentials
    include Jenkins::Helper

    resource_name :jenkins_secret_file_credentials

    # Attributes
    attribute :description,
              kind_of: String              
    attribute :filename,
              kind_of: String
    attribute :data,
              kind_of: String,
              required: true
  end
end

class Chef
  class Provider::JenkinsSecretFileCredentials < Provider::JenkinsCredentials
    provides :jenkins_secret_file_credentials

    def load_current_resource
      @current_resource ||= Resource::JenkinsSecretFileCredentials.new(new_resource.name)

      super

      if current_credentials
        @current_resource.filename(current_credentials[:filename])
        @current_resource.data(current_resource[:data])
      end

      @current_resource
    end

    protected

    #
    # @see Chef::Resource::JenkinsCredentials#credentials_groovy
    # @see https://github.com/jenkinsci/plain-credentials-plugin/blob/master/src/main/java/org/jenkinsci/plugins/plaincredentials/impl/FileCredentialsImpl.java
    #
    def credentials_groovy
      <<-EOH.gsub(/ ^{8}/, '')
        import com.cloudbees.plugins.credentials.CredentialsScope
        import java.nio.charset.StandardCharsets
        import org.apache.commons.codec.binary.Base64
        import org.apache.commons.fileupload.FileItem
        import org.apache.commons.fileupload.FileItemHeaders
        import org.apache.commons.lang.NotImplementedException
        import org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl

        class VirtualFileItem implements FileItem {
          String getName() { #{convert_to_groovy(new_resource.filename)} }
          byte[] get() { Base64.decodeBase64('#{new_resource.data}') }

          void delete() { throw new NotImplementedException() }
          String getContentType() { throw new NotImplementedException() }
          String getFieldName() { throw new NotImplementedException() }
          InputStream getInputStream() { throw new NotImplementedException() }
          OutputStream getOutputStream() { throw new NotImplementedException() }
          long getSize() { throw new NotImplementedException() }
          String getString() { throw new NotImplementedException() }
          String getString(String encoding) { throw new NotImplementedException() }
          boolean isFormField() { throw new NotImplementedException() }
          boolean isInMemory() { throw new NotImplementedException() }
          void setFieldName(String name) { throw new NotImplementedException() }
          void setFormField(boolean state) { throw new NotImplementedException() }
          void write(File file) { throw new NotImplementedException() }
          FileItemHeaders getHeaders() { throw new NotImplementedException() }
          void setHeaders(FileItemHeaders headers) { throw new NotImplementedException() }
        }

        credentials = new FileCredentialsImpl(
          CredentialsScope.GLOBAL,
          #{convert_to_groovy(new_resource.id)},
          #{convert_to_groovy(new_resource.description)},
          new VirtualFileItem(),
          null,
          (String)null
        )
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#resource_attributes_groovy
    #
    def resource_attributes_groovy(groovy_variable_name)
      <<-EOH.gsub(/ ^{8}/, '')
        #{groovy_variable_name} = [
          id:credentials.id,
          description:credentials.description,
        ]
      EOH
    end

    #
    # @see Chef::Resource::JenkinsCredentials#attribute_to_property_map
    #
    def attribute_to_property_map
      {
        filename: 'credentials.fileName',
        data: 'credentials.data'
      }
    end
  end
end
