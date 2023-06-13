require 'spec_helper'

describe Heapy::ReferenceExplorer do
  subject { described_class.new(file_name).drill_down(address) }

  let(:file_name) { 'spec/fixtures/dumps/01-ref-explore.dump' }
  let(:stdout) { StringIO.new }
  let(:output) { stdout.string }

  around(:each) do |ex|
    begin
      original = $stdout
      $stdout = stdout
      ex.run
    ensure
      $stdout = original
    end
  end

  describe 'when inspecting an object address' do
    let(:address) { '0x7f6bd8d961b0' }
    let(:expected_output) do
      <<~OUTPUT
        ## Reference chain
        <OBJECT MyClass 0x7F6BD8D961B0> (allocated at test.rb:5)
        <IMEMO env 0x7F6BD8D9A788> (allocated at )
        <DATA 0x7F6BD8D6A7B8> (allocated at )
        <ROOT vm 0x0> (allocated at )
      OUTPUT
    end

    it 'prints the reference chain' do
      subject

      expect(output).to include(expected_output)
    end

    context 'when passing the address in all-caps' do
      let(:address) { '0x7F6BD8D961B0' }

      it 'prints the reference chain' do
        subject

        expect(output).to include(expected_output)
      end
    end
  end

  describe 'when inspecting an invalid object address' do
    let(:address) { '0xdeadbeef' }

    it 'prints an error message' do
      subject

      expect(output).to include('Could not find a reference chain leading to a root node.')
    end
  end

  describe 'when inspecting an anonymous class with a live instance' do
    let(:address) { '0x7f6bd46fb868' }

    it 'indicates a reference by the live instance' do
      subject

      expect(output).to include('OBJECT MyClass')
    end
  end
end
