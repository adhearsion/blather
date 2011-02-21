class IPAddr
  PrivateRanges = [
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16")
  ]

  def private?
    return false unless self.ipv4?
    PrivateRanges.each do |ipr|
      return true if ipr.include?(self)
    end
    return false
  end

  def public?
    !private?
  end
end