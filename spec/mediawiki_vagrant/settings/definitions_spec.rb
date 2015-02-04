require 'spec_helper'
require 'mediawiki-vagrant/settings/definitions'

module MediaWikiVagrant
  describe Settings do
    context 'predefined settings' do
      let(:definitions) { Settings.definitions }

      describe 'git_user' do
        subject { definitions[:git_user] }

        it { is_expected.to have_attributes(allows_empty: true) }
      end

      describe 'vagrant_ram' do
        subject { definitions[:vagrant_ram] }

        it { is_expected.to have_attributes(default: 1024) }

        context 'when a new value is set' do
          context 'higher than the current value' do
            before { subject.value = 1025 }

            it 'uses the given value' do
              expect(subject.value).to eq(1025)
            end
          end

          context 'lower than the current value' do
            before { subject.value = 1023 }

            it 'retains its current value' do
              expect(subject.value).to eq(1024)
            end
          end
        end
      end

      describe 'vagrant_cores' do
        subject { definitions[:vagrant_cores] }

        it { is_expected.to have_attributes(default: 2) }

        context 'when a new value is set' do
          before { subject.value = '4' }

          it 'ensures it is an integer' do
            expect(subject.value).to eq(4)
          end
        end
      end

      describe 'static_ip' do
        subject { definitions[:static_ip] }

        it { is_expected.to have_attributes(default: '10.11.12.13') }
      end

      describe 'http_port' do
        subject { definitions[:http_port] }

        it { is_expected.to have_attributes(default: 8080) }

        context 'when a new value is set' do
          before { subject.value = '8081' }

          it 'ensures it is an integer' do
            expect(subject.value).to eq(8081)
          end
        end
      end

      describe 'nfs_shares' do
        subject { definitions[:nfs_shares] }

        context 'when a new value is set' do
          it 'considers values "true", "t", "yes", "y", "1" all to be true' do
            %w(true t yes y 1).each do |value|
              subject.value = value
              expect(subject.value).to be(true), "expected #{value} to be considered true"
            end
          end

          it 'considers values "false", "f", "no", "n", "0" to be false' do
            %w(false f no n 0).each do |value|
              subject.value = value
              expect(subject.value).to be(false), "expected #{value} to be considered false"
            end
          end
        end
      end

      describe 'forward_agent' do
        subject { definitions[:forward_agent] }

        it { is_expected.to have_attributes(default: false) }

        context 'when a new value is set' do
          it 'considers values "true", "t", "yes", "y", "1" to be true' do
            %w(true t yes y 1).each do |value|
              subject.value = value
              expect(subject.value).to be(true), "expected #{value} to be considered true"
            end
          end

          it 'considers values "false", "f", "no", "n", "0" to be false' do
            %w(false f no n 0).each do |value|
              subject.value = value
              expect(subject.value).to be(false), "expected #{value} to be considered false"
            end
          end
        end
      end

      describe 'forward_ports' do
        subject { definitions[:forward_ports] }

        it { is_expected.to have_attributes(internal: true, default: {}) }

        context 'when a new value is set' do
          before { subject.value = { '123' => '321', '789' => '987' } }

          it 'ensures it is a hash of integers' do
            expect(subject.value).to eq(123 => 321, 789 => 987)
          end

          context 'more than once' do
            before { subject.value = { '123' => '432' } }

            it 'merges it with the current value' do
              expect(subject.value).to eq(123 => 432, 789 => 987)
            end
          end
        end
      end
    end
  end
end
