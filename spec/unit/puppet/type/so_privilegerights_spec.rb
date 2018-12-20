require 'spec_helper'

describe Puppet::Type.type(:so_privilegerights) do
    let(:invalid_name) {'Manage invalide privilege right name'}
    let(:valid_name) {'Access this computer from the network'}
    let(:catalog) { Puppet::Resource::Catalog.new }

    context 'when using namevar' do
        it 'should have a namevar' do
            expect(described_class.key_attributes).to eq([:name])
        end
    end

    context 'when validating name with secedit_mappingtable' do
    # checking name with secedit_mapping.json
        it 'should fail with an invalid name' do
            expect {
                described_class.new(
                   :name => invalid_name,
                )
            }.to raise_error(Puppet::ResourceError, /Invalid display name: \'Manage invalide privilege right name\'/)
        end

        it 'should pass with a valid name' do
            expect {
                described_class.new(
                    :name => valid_name,
                )
            }.should be_truthy
        end
    end

    context 'when validating ensure' do
        it 'should be ensurable' do
            expect(described_class.attrtype(:ensure)).to eq(:property)
        end

        it 'should be ensured to present by default' do
            res = described_class.new(:title => valid_name)
            expect(res[:ensure]).to eq(:present)
        end

        it 'should be ensurable to absent' do
            res = described_class.new(
                :title  => valid_name,
                :ensure => :absent
            )
            expect(res[:ensure]).to eq(:absent)
        end
    end

    context 'when using ura fragments' do
        it 'should collect fragments in sid' do
            catalog.add_resource(Puppet::Type.type(:user_rights_assignment).new(
                :name  => 'seincreasequatoprivilege',
                :sid   => 'CORP\admin',
                :right => valid_name,
            ))
            catalog.add_resource(Puppet::Type.type(:user_rights_assignment).new(
                :name  => 'SeNetworkLogonRight',
                :sid   => ['*S-1-5-11', '*S-1-5-32-544'],
                :right => valid_name,
            ))

            res = described_class.new(
                :title  => valid_name,
                :ensure => :present,
                :sid    => [],
            )

            res.catalog = catalog

            expect(res.property(:sid).should).to eq (['CORP\admin', '*S-1-5-11', '*S-1-5-32-544'])
        end
    end
end
