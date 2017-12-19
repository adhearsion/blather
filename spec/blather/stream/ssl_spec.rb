require 'spec_helper'

describe Blather::CertStore do
  let(:cert_dir)  { File.expand_path '../../fixtures', File.dirname(__FILE__) }
  let(:cert_path) { File.join cert_dir, 'certificate.crt' }
  let(:cert)      { File.read cert_path }

  subject do
    Blather::CertStore.new cert_dir
  end

  it 'can verify valid cert' do
    expect(subject.trusted?(cert)).to be true
  end

  it 'can verify invalid cert' do
    expect(subject.trusted?(cert[0..(cert.length/2)])).to be_nil
  end

  it 'cannot verify when the cert authority is not trusted' do
    @store = Blather::CertStore.new("../")
    expect(@store.trusted?(cert)).to be false
  end
end
