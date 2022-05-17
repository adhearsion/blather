require 'spec_helper'

def ibr_xml
<<-XML
<iq type='result' id='reg1'>
  <query xmlns='jabber:iq:register'>
    <instructions>
      Choose a username and password for use with this service.
      Please also provide your email address.
    </instructions>
    <username/>
    <password/>
    <email/>
  </query>
</iq>
XML
end

describe Blather::Stanza::Iq::IBR do
  let(:ibr) { Blather::Stanza::Iq::IBR.new }
  let(:test_string) { "<a&a>" }

  it 'registers itself' do
    expect(Blather::XMPPNode.class_from_registration(:query, 'jabber:iq:register')).to eq(Blather::Stanza::Iq::IBR)
  end

  it 'can be imported' do
    node = Blather::XMPPNode.parse ibr_xml
    expect(node).to be_instance_of Blather::Stanza::Iq::IBR
  end

  describe '#registered' do
    subject { ibr.registered? }

    it { is_expected.to be false }

    context 'true' do
      let(:is_registered) { true }

      subject do
        ibr.registered = is_registered
        ibr.registered?
      end

      it { is_expected.to be true }
    end

    context 'false' do
      let(:is_registered) { false }

      subject do
        ibr.registered = is_registered
        ibr.registered?
      end

      it { is_expected.to be false }
    end
  end

  describe '#remove?' do
    subject { ibr.remove? }

    it { is_expected.to be false }

    context '#remove!' do
      subject do
        ibr.remove!
        ibr.remove?
      end

      it { is_expected.to be true }
    end
  end

  describe '#form' do
    subject { ibr.form }

    it { is_expected.to be_instance_of Blather::Stanza::X }
  end

  describe '#instructions' do
    subject do
      ibr.instructions = test_string
      ibr.instructions
    end

    it { is_expected.to eq test_string }
  end

  describe '#username' do
    subject do
      ibr.username = test_string
      ibr.username
    end

    it { is_expected.to eq test_string }
  end

  describe '#nick' do
    subject do
      ibr.nick = test_string
      ibr.nick
    end

    it { is_expected.to eq test_string }
  end

  describe '#password' do
    subject do
      ibr.password = test_string
      ibr.password
    end

    it { is_expected.to eq test_string }
  end

  describe '#name' do
    subject do
      ibr.name = test_string
      ibr.name
    end

    it { is_expected.to eq test_string }
  end

  describe '#first' do
    subject do
      ibr.first = test_string
      ibr.first
    end

    it { is_expected.to eq test_string }
  end

  describe '#last' do
    subject do
      ibr.last = test_string
      ibr.last
    end

    it { is_expected.to eq test_string }
  end

  describe '#email' do
    subject do
      ibr.email = test_string
      ibr.email
    end

    it { is_expected.to eq test_string }
  end

  describe '#address' do
    subject do
      ibr.address = test_string
      ibr.address
    end

    it { is_expected.to eq test_string }
  end

  describe '#city' do
    subject do
      ibr.city = test_string
      ibr.city
    end

    it { is_expected.to eq test_string }
  end

  describe '#state' do
    subject do
      ibr.state = test_string
      ibr.state
    end

    it { is_expected.to eq test_string }
  end

  describe '#zip' do
    subject do
      ibr.zip = test_string
      ibr.zip
    end

    it { is_expected.to eq test_string }
  end

  describe '#phone' do
    subject do
      ibr.phone = test_string
      ibr.phone
    end

    it { is_expected.to eq test_string }
  end

  describe '#url' do
    subject do
      ibr.url = test_string
      ibr.url
    end

    it { is_expected.to eq test_string }
  end

  describe '#date' do
    subject do
      ibr.date = test_string
      ibr.date
    end

    it { is_expected.to eq test_string }
  end
end
