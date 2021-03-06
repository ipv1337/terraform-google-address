# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

project_id        = attribute('project_id')
addresses         = attribute('addresses')
dns_fqdns         = attribute('dns_fqdns')
reverse_dns_fqdns = attribute('reverse_dns_fqdns')
names             = attribute('names')
forward_zone      = attribute('forward_zone')
reverse_zone      = attribute('reverse_zone')

control "dns-forward-and-reverse" do
  title "Address module - DNS example with forward and reverse lookup registration"

  describe command("gcloud projects describe #{project_id}") do
    its('exit_status') { should be 0 }
    its('stderr') { should eq '' }
  end

  addresses.each_with_index do |ip_address, index|
    describe command("gcloud compute addresses list --project #{project_id}  --format='json' --filter=address:#{ip_address}") do
      its('exit_status') { should be 0 }
      its('stderr') { should eq '' }

      let(:attributes) do
        if subject.exit_status == 0
          JSON.parse(subject.stdout, symbolize_names: true)
        else
          {}
        end
      end

      it "lists all reserved IP addresses" do
        expect(attributes.first).to include(
          name: "#{names[index]}"
        )
      end
    end
  end

  reverse_dns_fqdns.each_with_index do |reverse_fqdn, index|
    describe command("gcloud dns record-sets list --project #{project_id} --zone=#{reverse_zone} --format='json' --filter=name:#{reverse_fqdn}.") do
      its('exit_status') { should be 0 }
      its('stderr') { should eq '' }

      let(:attributes) do
        if subject.exit_status == 0
          JSON.parse(subject.stdout, symbolize_names: true)
        else
          {}
        end
      end

      it "matches the reverse DNS PTR record to the matching FQDN" do
        expect(attributes.first).to include(
          rrdatas: ["#{dns_fqdns[index]}."]
        )
      end
    end
  end

  dns_fqdns.each_with_index do |fqdn, index|
    describe command("gcloud dns record-sets list --project #{project_id} --zone=#{forward_zone} --format='json' --filter=name:#{fqdn}") do
      its('exit_status') { should be 0 }
      its('stderr') { should eq '' }

      let(:attributes) do
        if subject.exit_status == 0
          JSON.parse(subject.stdout, symbolize_names: true)
        else
          {}
        end
      end

      it "matches the FQDN to the correct IP address" do
        expect(attributes.first).to include(
          rrdatas: ["#{addresses[index]}"]
        )
      end
    end
  end
end
