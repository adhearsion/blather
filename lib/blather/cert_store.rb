# encoding: UTF-8

module Blather

  # An X509 certificate store that validates certificate trust chains.
  # This uses the #{cert_directory}/*.crt files as the list of trusted root
  # CA certificates.
  class CertStore
    def initialize(cert_directory)
      @cert_directory = cert_directory
      @store = OpenSSL::X509::Store.new
      certs.each {|c| @store.add_cert(c) }
    end

    # Return true if the certificate is signed by a CA certificate in the
    # store. If the certificate can be trusted, it's added to the store so
    # it can be used to trust other certs.
    def trusted?(pem)
      if cert = OpenSSL::X509::Certificate.new(pem)
        @store.verify(cert).tap do |trusted|
          begin
            @store.add_cert(cert) if trusted
          rescue OpenSSL::X509::StoreError
          end
        end
      end
    rescue OpenSSL::X509::CertificateError
      nil
    end

    # Return true if the domain name matches one of the names in the
    # certificate. In other words, is the certificate provided to us really
    # for the domain to which we think we're connected?
    def domain?(pem, domain)
      if cert = OpenSSL::X509::Certificate.new(pem)
        OpenSSL::SSL.verify_certificate_identity(cert, domain)
      end
    end

    # Return the trusted root CA certificates installed in the @cert_directory. These
    # certificates are used to start the trust chain needed to validate certs
    # we receive from clients and servers.
    def certs
      @certs ||= begin
        pattern = /-{5}BEGIN CERTIFICATE-{5}\n.*?-{5}END CERTIFICATE-{5}\n/m
        Dir[File.join(@cert_directory, '*.crt')]
          .map {|f| File.read(f) }
          .map {|c| c.scan(pattern) }
          .flatten
          .map {|c| OpenSSL::X509::Certificate.new(c) }
          .reject {|c| c.not_after < Time.now }
      end
    end
  end
end
