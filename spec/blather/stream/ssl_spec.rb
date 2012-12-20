require 'spec_helper'

describe Blather::CertStore do
  before do
    @pem = "-----BEGIN CERTIFICATE-----\nMIIDszCCApugAwIBAgIETiZC5TANBgkqhkiG9w0BAQUFADBjMQswCQYDVQQGEwJV\nUzERMA8GA1UECAwIQ29sb3JhZG8xDzANBgNVBAcMBkRlbnZlcjEaMBgGA1UECgwR\nVmluZXMgWE1QUCBTZXJ2ZXIxFDASBgNVBAMMC3ZpbmVzLmxvY2FsMB4XDTExMDcx\nOTAyNTIyMVoXDTEyMDcxOTAyNTIyMVowYzELMAkGA1UEBhMCVVMxETAPBgNVBAgM\nCENvbG9yYWRvMQ8wDQYDVQQHDAZEZW52ZXIxGjAYBgNVBAoMEVZpbmVzIFhNUFAg\nU2VydmVyMRQwEgYDVQQDDAt2aW5lcy5sb2NhbDCCASIwDQYJKoZIhvcNAQEBBQAD\nggEPADCCAQoCggEBAMyqj4UyXIpLYyIDaqDoN/8yZHDv281lz1UzuhPZ5r4S6teA\n90dXT6MxEoQ5vpRV2lVU21mDOoRPk9qjgGA01zimrX/YvPf2BBedFkvU18ZKiOMD\n7D89Ej2oIPLc6dJMiIx1SbfpdvUtVZFn1/jGvQPv5iajHW5n/zn1KrHOvVa6R5eY\nVGEH3DD3RkzSxWHyiNN8R5SQzyOVX9F4DVFAffPOLbkFsCi2POy3dp+ZWuYKEjBd\nMuRibrt87PCESnyXZx/Y+GBG856wQT8Ny6mmnh5z5YtopvAJh16ps2p6DFgyDtF+\nhaW3WMlStXYQPqSTrreD7qdAxi3rVft2OUJLTJkCAwEAAaNvMG0wDAYDVR0TBAUw\nAwEB/zAdBgNVHQ4EFgQUUCSlixByIPK3s20w4xHhcMax7igwPgYDVR0RBDcwNYIL\ndmluZXMubG9jYWyCJmNocmlzdG9waGVyLWpvaG5zb25zLW1hY2Jvb2stcHJvLmxv\nY2FsMA0GCSqGSIb3DQEBBQUAA4IBAQBOy1nI7H8XpnpVzpRK5RN/MzelQUl1Efo0\nl9wZ73E6EgJinl2AUp1/sYMUWkVlZ4DSflRBxBEp0CAJNoUydBh8O1xEKGTyqlLy\n/daqvNFLnYwFluAWi1xJQZv4AE62ua5wjsrhPuu3aMvPt9hx1X3CVh+8aA24/gAo\nAPJYsfT3T8GCD+MU3Uc2yADnLSUJ6Jal56/okOJA2Pfkr/K4zj1CyfAEWlpgo2Pv\nyrpv4V2WP1SL5fOONNGfOzio1LD6seAl+8SjiCefnMan2aXmna6SpMDzXB8vTDUE\nWmsD9g0621WqNz2x6lY5IYr7azE2C46Tpb9FOeSAAd83Zka4acaL\n-----END CERTIFICATE-----\n"
    @cert = File.open("./test.crt", 'w') {|f| f.write(@pem) }
    @store = Blather::CertStore.new("./")
  end

  after do
    File.delete("./test.crt")
  end

  it 'can verify valid cert' do
    @store.trusted?(@pem).should == true
  end

  it 'can verify invalid cert' do
    @store.trusted?(@pem.gsub("L", "a")).should == nil
  end

  it 'can verify without a cert store' do
    @store = Blather::CertStore.new("../")
    @store.trusted?(@pem).should == true
  end
end
