require "blather/client/client"
require "openssl"
require "em-http"
require "cgi"

module S3FileReceiver
  def initialize(iq)
    p "initialize"
    @filename = iq.si.file["name"]
    @size = iq.si.file["size"].to_i
  end
  
  def post_init
    p "post_init"
    time = Time.now.httpdate
    sign = Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha1'), "qHG5ywFiZR2EK7oUvLVLhGHr2Rp05ggriTdExw0I", "PUT\n\n\n#{time}\n/jaconda-dev/#{CGI::escape(@filename)}")).strip
    @s3 = EM::HttpRequest.new("https://jaconda-dev.s3.amazonaws.com:443/#{CGI::escape(@filename)}").put({:timeout => 10, :head => {'date' => time, 'url' => "/jaconda-dev/#{CGI::escape(@filename)}", 'Content-Length' => @size, "Authorization" => "AWS AKIAIVULGEHUOR7PIR4Q:#{sign}"}})
    @s3.errback do |e|
      p "error: #{e.response_header.inspect}"
    end
    @s3.callback do |s|
      p "success: #{s.response.inspect}"
    end
    EM::enable_proxy(self, @s3)
  end
  
  def proxy_target_unbound
    close_connection_after_writing
  end
end

EM.run do
  Blather.logger = Logger.new("/Users/antonmironov/Desktop/blather.log")
  Blather.logger.level = Logger::DEBUG

  im = Blather::Client.setup "ant.mironov@jabber.ru/test", "zzzxxx"

  im.register_handler :disco_info, :type => :get do |iq|
    answer = iq.reply
    answer.identities = [{:type => 'pc', :category => 'client'}]
    answer.features = ["http://jabber.org/protocol/si/profile/file-transfer", "http://jabber.org/protocol/si", "http://jabber.org/protocol/bytestreams", "http://jabber.org/protocol/ibb"]

    im.write answer
  end

  im.register_handler :file_transfer do |iq|
    transfer = Blather::FileTransfer.new(im, iq)
#    transfer.allow_bytestreams = false

    transfer.accept(S3FileReceiver, iq)

    true
  end
  im.connect
end