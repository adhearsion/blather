# Blather

[![Gem Version](https://badge.fury.io/rb/blather.png)](https://rubygems.org/gems/blather)
[![Build Status](https://secure.travis-ci.org/adhearsion/blather.png?branch=develop)](http://travis-ci.org/adhearsion/blather)
[![Dependency Status](https://gemnasium.com/adhearsion/blather.png?travis)](https://gemnasium.com/adhearsion/blather)
[![Code Climate](https://codeclimate.com/github/adhearsion/blather.png)](https://codeclimate.com/github/adhearsion/blather)
[![Coverage Status](https://coveralls.io/repos/adhearsion/blather/badge.png?branch=develop)](https://coveralls.io/r/adhearsion/blather)
[![Inline docs](http://inch-ci.org/github/adhearsion/blather.png?branch=develop)](http://inch-ci.org/github/adhearsion/blather)

XMPP DSL (and more) for Ruby written on [EventMachine](http://rubyeventmachine.com/) and [Nokogiri](http://nokogiri.org/).

## Features

* evented architecture
* uses Nokogiri
* simplified starting point

## Project Pages

* [GitHub](https://github.com/adhearsion/blather)
* [Rubygems](http://rubygems.org/gems/blather)
* [API Documentation](http://rdoc.info/gems/blather/file/README.md)
* [Google Group](http://groups.google.com/group/xmpp-blather)

# Usage

## Installation

    gem install blather

## Example

Blather comes with a DSL that makes writing XMPP bots quick and easy. See the examples directory for more advanced examples.

```ruby
require 'blather/client'

setup 'echo@jabber.local', 'echo'

# Auto approve subscription requests
subscription :request? do |s|
  write_to_stream s.approve!
end

# Echo back what was said
message :chat?, :body do |m|
  write_to_stream m.reply
end
```

The above example is for a standalone script, and [can be run as a command line program](https://github.com/adhearsion/blather#on-the-command-line). If you wish to integrate Blather into an existing application, you will need to avoid `blather/client` and instead do something like this:

```ruby
require 'blather/client/dsl'

module App
  extend Blather::DSL

  def self.run
    EM.run { client.run }
  end

  setup 'echo@jabber.local', 'echo'

  # Auto approve subscription requests
  subscription :request? do |s|
    write_to_stream s.approve!
  end

  # Echo back what was said
  message :chat?, :body do |m|
    write_to_stream m.reply
  end
end

trap(:INT) { EM.stop }
trap(:TERM) { EM.stop }

App.run
```

If you need to ensure that Blather does not block the rest of your application, run the reactor in a new thread:

```ruby
Thread.new { App.run }
```

You can additionally send messages like so:

```ruby
App.say 'foo@bar.com', 'Hello there!'
```

## Handlers

Handlers let Blather know how you'd like each type of stanza to be well.. handled. Each type of stanza has an associated handler which is part of a handler hierarchy. In the example above we're handling message and subscription stanzas.

XMPP is built on top of three main stanza types (presence, message, and iq). All other stanzas are built on these three base types. This creates a natural hierarchy of handlers. For example a subscription stanza is a type of presence stanza and can be processed by a subscription handler or a presence handler. Likewise, a PubSub::Items stanza has its own identifier :pubsub_items but it's also a :pubsub_node, :iq and :staza. Any or each of these could be used to handle the PubSub::Items stanza. If you've done any DOM programming you'll be familiar with this.

Incoming stanzas will be handled by the first handler found. Unlike the DOM this will stop the handling bubble unless the handler returns false.

The entire handler hierarchy can be seen below.

### Example

Here we have a presence handler and a subscription handler. When this script receives a subscription stanza the subscription handler will be notified first. If that handler doesn't know what to do it can return false and let the stanza bubble up to the presence handler.

```ruby
# Handle all presence stanzas
presence do |stanza|
  # do stuff
end

# Handle all subscription stanzas
subscription do |stanza|
  # do stuff
end
```

Additionally, handlers may be 'guarded'. That is, they may have conditions set declaratively, against which the stanza must match in order to trigger the handler.

```ruby
# Will only be called for messages where #chat? responds positively
# and #body == 'exit'
message :chat?, :body => 'exit'
```

### Non-Stanza Handlers

So far there are two non-stanza related handlers.

```ruby
# Called after the connection has been connected. It's good for initializing
# your system.
# DSL:
when_ready {}
# Client:
client.register_handler(:ready) {}

# Called after the connection has been terminated. Good for teardown or
# automatic reconnection.
# DSL:
disconnected {}
# Client
client.register_handler(:disconnected) {}
# The following will reconnect every time the connection is lost:
disconnected { client.connect }
```

### Handler Guards

Guards are a concept borrowed from Erlang. They help to better compartmentalize handlers.

There are a number of guard types and one bit of special syntax. Guards act like AND statements. Each condition must be met if the handler is to
be used.

```ruby
# Equivalent to saying (stanza.chat? && stanza.body)
message :chat?, :body
```

The different types of guards are:

```ruby
# Symbol
#   Checks for a non-false reply to calling the symbol on the stanza
#   Equivalent to stanza.chat?
message :chat?

# Hash with any value (:body => 'exit')
#   Calls the key on the stanza and checks for equality
#   Equivalent to stanza.body == 'exit'
message :body => 'exit'

# Hash with regular expression (:body => /exit/)
#   Calls the key on the stanza and checks for a match
#   Equivalent to stanza.body.match /exit/
message :body => /exit/

# Hash with array (:name => [:gone, :forbidden])
#   Calls the key on the stanza and check for inclusion in the array
#   Equivalent to [:gone, :forbidden].include?(stanza.name)
stanza_error :name => [:gone, :fobidden]

# Proc
#   Calls the proc passing in the stanza
#   Checks that the ID is modulo 3
message proc { |m| m.id % 3 == 0 }

# Array
#   Use arrays with the previous types effectively turns the guard into
#   an OR statement.
#   Equivalent to stanza.body == 'foo' || stanza.body == 'baz'
message [{:body => 'foo'}, {:body => 'baz'}]

# XPath
#   Runs the xpath query on the stanza and checks for results
#   This guard type cannot be combined with other guards
#   Equivalent to !stanza.find('/iq/ns:pubsub', :ns => 'pubsub:namespace').empty?
#   It also passes two arguments into the handler block: the stanza and the result
#   of the xpath query.
iq '/iq/ns:pubsub', :ns => 'pubsub:namespace' do |stanza, xpath_result|
  # stanza will be the original stanza
  # xpath_result will be the pubsub node in the stanza
end
```

### Filters

Blather provides before and after filters that work much the way regular
handlers work. Filters come in a before and after flavor. They're called in
order of definition and can be guarded like handlers.

```ruby
before { |s| "I'm run before any handler" }
before { |s| "I'm run next" }

before(:message) { |s| "I'm only run in front of message stanzas" }
before(nil, :id => 1) { |s| "I'll only be run when the stanza's ID == 1" }

# ... handlers

after { |s| "I'm run after everything" }
```

### Handlers Hierarchy

```
stanza
|- iq
|  |- pubsub_node
|  |  |- pubsub_affiliations
|  |  |- pubsub_create
|  |  |- pubsub_items
|  |  |- pubsub_publish
|  |  |- pubsub_retract
|  |  |- pubsub_subscribe
|  |  |- pubsub_subscription
|  |  |- pubsub_subscriptions
|  |  `- pubsub_unsubscribe
|  |- pubsub_owner
|  |  |- pubsub_delete
|  |  `- pubsub_purge
|  `- query
|     |- disco_info
|     |- disco_items
|     `- roster
|- message
|  `- pubsub_event
`- presence
   |- status
   `- subscription

error
|- argument_error
|- parse_error
|- sasl_error
|- sasl_unknown_mechanism
|- stanza_error
|- stream_error
|- tls_failure
`- unknown_response_error
```

## On the Command Line

Default usage is:

```
[blather_script] [options] node@domain.com/resource password [host] [port]
```

Command line options:

```
-D, --debug       Run in debug mode (you will see all XMPP communication)
-d, --daemonize   Daemonize the process
    --pid=[PID]   Write the PID to this file
    --log=[LOG]   Write to the [LOG] file instead of stdout/stderr
-h, --help        Show this message
-v, --version     Show version
```

## Health warning

Some parts of Blather will allow you to do stupid things that don't conform to XMPP
spec. You should exercise caution and read the relevant specifications (indicated in
the preamble to most relevant classes).

## Spec compliance

Blather provides support in one way or another for many XMPP specifications. Below is a list of specifications and the status of support for them in Blather. This list *may not be correct*. If the list indicates a lack of support for a specification you wish to use, you are encouraged to check that this is correct. Likewise, if you find an overstatement of Blather's spec compliance, please point this out. Also note that even without built-in support for a specification, you can still manually construct and parse stanzas alongside use of Blather's built-in helpers.

Specification                                        | Support | Name | Notes
---------------------------------------------------- | ------- | ---- | -----
[RFC 6120](http://tools.ietf.org/html/rfc6120)       | Full    | XMPP: Core |
[RFC 6121](http://tools.ietf.org/html/rfc6121)       | Full    | XMPP: Instant Messaging and Presence |
[RFC 6122](http://tools.ietf.org/html/rfc6122)       | Full    | XMPP: Address Format |
[XEP-0001](http://xmpp.org/extensions/xep-0001.html) | N/A     | XMPP Extension Protocols |
[XEP-0002](http://xmpp.org/extensions/xep-0002.html) | N/A     | Special Interest Groups (SIGs) |
[XEP-0004](http://xmpp.org/extensions/xep-0004.html) | Partial | Data Forms |
[XEP-0009](http://xmpp.org/extensions/xep-0009.html) | None    | Jabber-RPC |
[XEP-0012](http://xmpp.org/extensions/xep-0012.html) | None    | Last Activity |
[XEP-0013](http://xmpp.org/extensions/xep-0013.html) | None    | Flexible Offline Message Retrieval |
[XEP-0016](http://xmpp.org/extensions/xep-0016.html) | None    | Privacy Lists |
[XEP-0019](http://xmpp.org/extensions/xep-0019.html) | N/A     | Streamlining the SIGs |
[XEP-0020](http://xmpp.org/extensions/xep-0020.html) | Partial | Feature Negotiation |
[XEP-0027](http://xmpp.org/extensions/xep-0027.html) | None    | Current Jabber OpenPGP Usage |
[XEP-0030](http://xmpp.org/extensions/xep-0030.html) | Partial | Service Discovery |
[XEP-0033](http://xmpp.org/extensions/xep-0033.html) | None    | Extended Stanza Addressing |
[XEP-0045](http://xmpp.org/extensions/xep-0045.html) | Partial | Multi-User Chat |
[XEP-0047](http://xmpp.org/extensions/xep-0047.html) | None    | In-Band Bytestreams |
[XEP-0048](http://xmpp.org/extensions/xep-0048.html) | None    | Bookmarks |
[XEP-0049](http://xmpp.org/extensions/xep-0049.html) | None    | Private XML Storage |
[XEP-0050](http://xmpp.org/extensions/xep-0050.html) | Partial | Ad-Hoc Commands |
[XEP-0053](http://xmpp.org/extensions/xep-0053.html) | None    | XMPP Registrar Function |
[XEP-0054](http://xmpp.org/extensions/xep-0054.html) | None    | vcard-temp |
[XEP-0055](http://xmpp.org/extensions/xep-0055.html) | None    | Jabber Search |
[XEP-0059](http://xmpp.org/extensions/xep-0059.html) | None    | Result Set Management |
[XEP-0060](http://xmpp.org/extensions/xep-0060.html) | Partial | Publish-Subscribe |
[XEP-0065](http://xmpp.org/extensions/xep-0065.html) | None    | SOCKS5 Bytestreams |
[XEP-0066](http://xmpp.org/extensions/xep-0066.html) | None    | Out of Band Data |
[XEP-0068](http://xmpp.org/extensions/xep-0068.html) | None    | Field Standardization for Data Forms |
[XEP-0070](http://xmpp.org/extensions/xep-0070.html) | None    | Verifying HTTP Requests via XMPP |
[XEP-0071](http://xmpp.org/extensions/xep-0071.html) | Partial | XHTML-IM |
[XEP-0072](http://xmpp.org/extensions/xep-0072.html) | None    | SOAP Over XMPP |
[XEP-0076](http://xmpp.org/extensions/xep-0076.html) | None    | Malicious Stanzas |
[XEP-0077](http://xmpp.org/extensions/xep-0077.html) | Full    | In-Band Registration |
[XEP-0079](http://xmpp.org/extensions/xep-0079.html) | None    | Advanced Message Processing |
[XEP-0080](http://xmpp.org/extensions/xep-0080.html) | None    | User Location |
[XEP-0082](http://xmpp.org/extensions/xep-0082.html) | None    | XMPP Date and Time Profiles |
[XEP-0083](http://xmpp.org/extensions/xep-0083.html) | None    | Nested Roster Groups |
[XEP-0084](http://xmpp.org/extensions/xep-0084.html) | None    | User Avatar |
[XEP-0085](http://xmpp.org/extensions/xep-0085.html) | Partial | Chat State Notifications |
[XEP-0092](http://xmpp.org/extensions/xep-0092.html) | None    | Software Version |
[XEP-0095](http://xmpp.org/extensions/xep-0095.html) | Partial | Stream Initiation |
[XEP-0096](http://xmpp.org/extensions/xep-0096.html) | Partial | SI File Transfer |
[XEP-0100](http://xmpp.org/extensions/xep-0100.html) | None    | Gateway Interaction |
[XEP-0106](http://xmpp.org/extensions/xep-0106.html) | None    | JID Escaping |
[XEP-0107](http://xmpp.org/extensions/xep-0107.html) | None    | User Mood |
[XEP-0108](http://xmpp.org/extensions/xep-0108.html) | None    | User Activity |
[XEP-0114](http://xmpp.org/extensions/xep-0114.html) | Full    | Jabber Component Protocol |
[XEP-0115](http://xmpp.org/extensions/xep-0115.html) | Partial | Entity Capabilities |
[XEP-0118](http://xmpp.org/extensions/xep-0118.html) | None    | User Tune |
[XEP-0122](http://xmpp.org/extensions/xep-0122.html) | None    | Data Forms Validation |
[XEP-0124](http://xmpp.org/extensions/xep-0124.html) | None    | Bidirectional-streams Over Synchronous HTTP (BOSH) |
[XEP-0126](http://xmpp.org/extensions/xep-0126.html) | None    | Invisibility |
[XEP-0127](http://xmpp.org/extensions/xep-0127.html) | None    | Common Alerting Protocol (CAP) Over XMPP |
[XEP-0128](http://xmpp.org/extensions/xep-0128.html) | None    | Service Discovery Extensions |
[XEP-0130](http://xmpp.org/extensions/xep-0130.html) | None    | Waiting Lists |
[XEP-0131](http://xmpp.org/extensions/xep-0131.html) | None    | Stanza Headers and Internet Metadata |
[XEP-0132](http://xmpp.org/extensions/xep-0132.html) | None    | Presence Obtained via Kinesthetic Excitation (POKE) |
[XEP-0133](http://xmpp.org/extensions/xep-0133.html) | None    | Service Administration |
[XEP-0134](http://xmpp.org/extensions/xep-0134.html) | None    | XMPP Design Guidelines |
[XEP-0136](http://xmpp.org/extensions/xep-0136.html) | None    | Message Archiving |
[XEP-0137](http://xmpp.org/extensions/xep-0137.html) | None    | Publishing Stream Initiation Requests |
[XEP-0138](http://xmpp.org/extensions/xep-0138.html) | None    | Stream Compression |
[XEP-0141](http://xmpp.org/extensions/xep-0141.html) | None    | Data Forms Layout |
[XEP-0143](http://xmpp.org/extensions/xep-0143.html) | None    | Guidelines for Authors of XMPP Extension Protocols |
[XEP-0144](http://xmpp.org/extensions/xep-0144.html) | N/A     | Roster Item Exchange |
[XEP-0145](http://xmpp.org/extensions/xep-0145.html) | None    | Annotations |
[XEP-0146](http://xmpp.org/extensions/xep-0146.html) | None    | Remote Controlling Clients |
[XEP-0147](http://xmpp.org/extensions/xep-0147.html) | None    | XMPP URI Scheme Query Components |
[XEP-0148](http://xmpp.org/extensions/xep-0148.html) | None    | Instant Messaging Intelligence Quotient (IM IQ) |
[XEP-0149](http://xmpp.org/extensions/xep-0149.html) | None    | Time Periods |
[XEP-0153](http://xmpp.org/extensions/xep-0153.html) | None    | vCard-Based Avatars |
[XEP-0155](http://xmpp.org/extensions/xep-0155.html) | None    | Stanza Session Negotiation |
[XEP-0156](http://xmpp.org/extensions/xep-0156.html) | None    | Discovering Alternative XMPP Connection Methods |
[XEP-0157](http://xmpp.org/extensions/xep-0157.html) | None    | Contact Addresses for XMPP Services |
[XEP-0158](http://xmpp.org/extensions/xep-0158.html) | None    | CAPTCHA Forms |
[XEP-0160](http://xmpp.org/extensions/xep-0160.html) | None    | Best Practices for Handling Offline Messages |
[XEP-0163](http://xmpp.org/extensions/xep-0163.html) | Partial | Personal Eventing Protocol |
[XEP-0166](http://xmpp.org/extensions/xep-0166.html) | None    | Jingle |
[XEP-0167](http://xmpp.org/extensions/xep-0167.html) | None    | Jingle RTP Sessions |
[XEP-0169](http://xmpp.org/extensions/xep-0169.html) | None    | Twas The Night Before Christmas (Jabber Version) |
[XEP-0170](http://xmpp.org/extensions/xep-0170.html) | None    | Recommended Order of Stream Feature Negotiation |
[XEP-0171](http://xmpp.org/extensions/xep-0171.html) | None    | Language Translation |
[XEP-0172](http://xmpp.org/extensions/xep-0172.html) | None    | User Nickname |
[XEP-0174](http://xmpp.org/extensions/xep-0174.html) | None    | Serverless Messaging |
[XEP-0175](http://xmpp.org/extensions/xep-0175.html) | None    | Best Practices for Use of SASL ANONYMOUS |
[XEP-0176](http://xmpp.org/extensions/xep-0176.html) | None    | Jingle ICE-UDP Transport Method |
[XEP-0177](http://xmpp.org/extensions/xep-0177.html) | None    | Jingle Raw UDP Transport Method |
[XEP-0178](http://xmpp.org/extensions/xep-0178.html) | None    | Best Practices for Use of SASL EXTERNAL with Certificates |
[XEP-0182](http://xmpp.org/extensions/xep-0182.html) | N/A     | Application-Specific Error Conditions |
[XEP-0183](http://xmpp.org/extensions/xep-0183.html) | None    | Jingle Telepathy Transport |
[XEP-0184](http://xmpp.org/extensions/xep-0184.html) | None    | Message Delivery Receipts |
[XEP-0185](http://xmpp.org/extensions/xep-0185.html) | None    | Dialback Key Generation and Validation |
[XEP-0191](http://xmpp.org/extensions/xep-0191.html) | None    | Blocking Command|
[XEP-0198](http://xmpp.org/extensions/xep-0198.html) | None    | Stream Management |
[XEP-0199](http://xmpp.org/extensions/xep-0199.html) | Partial | XMPP Ping |
[XEP-0201](http://xmpp.org/extensions/xep-0201.html) | None    | Best Practices for Message Threads |
[XEP-0202](http://xmpp.org/extensions/xep-0202.html) | None    | Entity Time |
[XEP-0203](http://xmpp.org/extensions/xep-0203.html) | Partial | Delayed Delivery |
[XEP-0205](http://xmpp.org/extensions/xep-0205.html) | None    | Best Practices to Discourage Denial of Service Attacks |
[XEP-0206](http://xmpp.org/extensions/xep-0206.html) | None    | XMPP Over BOSH |
[XEP-0207](http://xmpp.org/extensions/xep-0207.html) | None    | XMPP Eventing via Pubsub |
[XEP-0220](http://xmpp.org/extensions/xep-0220.html) | None    | Server Dialback |
[XEP-0221](http://xmpp.org/extensions/xep-0221.html) | None    | Data Forms Media Element |
[XEP-0222](http://xmpp.org/extensions/xep-0222.html) | None    | Persistent Storage of Public Data via PubSub |
[XEP-0223](http://xmpp.org/extensions/xep-0223.html) | None    | Persistent Storage of Private Data via PubSub |
[XEP-0224](http://xmpp.org/extensions/xep-0224.html) | None    | Attention |
[XEP-0227](http://xmpp.org/extensions/xep-0227.html) | None    | Portable Import/Export Format for XMPP-IM Servers |
[XEP-0229](http://xmpp.org/extensions/xep-0229.html) | None    | Stream Compression with LZW |
[XEP-0231](http://xmpp.org/extensions/xep-0231.html) | None    | Bits of Binary |
[XEP-0233](http://xmpp.org/extensions/xep-0233.html) | None    | Domain-Based Service Names in XMPP SASL Negotiation |
[XEP-0234](http://xmpp.org/extensions/xep-0234.html) | None    | Jingle File Transfer |
[XEP-0239](http://xmpp.org/extensions/xep-0239.html) | None    | Binary XMPP |
[XEP-0242](http://xmpp.org/extensions/xep-0242.html) | None    | XMPP Client Compliance 2009 |
[XEP-0243](http://xmpp.org/extensions/xep-0243.html) | None    | XMPP Server Compliance 2009 |
[XEP-0245](http://xmpp.org/extensions/xep-0245.html) | None    | The /me Command |
[XEP-0249](http://xmpp.org/extensions/xep-0249.html) | None    | Direct MUC Invitations |
[XEP-0256](http://xmpp.org/extensions/xep-0256.html) | None    | Last Activity in Presence |
[XEP-0258](http://xmpp.org/extensions/xep-0258.html) | None    | Security Labels in XMPP |
[XEP-0260](http://xmpp.org/extensions/xep-0260.html) | None    | Jingle SOCKS5 Bytestreams Transport Method |
[XEP-0261](http://xmpp.org/extensions/xep-0261.html) | None    | Jingle In-Band Bytestreams Transport Method |
[XEP-0262](http://xmpp.org/extensions/xep-0262.html) | None    | Use of ZRTP in Jingle RTP Sessions |
[XEP-0263](http://xmpp.org/extensions/xep-0263.html) | None    | ECO-XMPP |
[XEP-0266](http://xmpp.org/extensions/xep-0266.html) | None    | Codecs for Jingle Audio |
[XEP-0267](http://xmpp.org/extensions/xep-0267.html) | None    | Server Buddies |
[XEP-0270](http://xmpp.org/extensions/xep-0270.html) | None    | XMPP Compliance Suites 2010 |
[XEP-0273](http://xmpp.org/extensions/xep-0273.html) | None    | Stanza Interception and Filtering Technology (SIFT) |
[XEP-0277](http://xmpp.org/extensions/xep-0277.html) | None    | Microblogging over XMPP |
[XEP-0278](http://xmpp.org/extensions/xep-0278.html) | None    | Jingle Relay Nodes |
[XEP-0280](http://xmpp.org/extensions/xep-0280.html) | None    | Message Carbons |
[XEP-0288](http://xmpp.org/extensions/xep-0288.html) | None    | Bidirectional Server-to-Server Connections |
[XEP-0292](http://xmpp.org/extensions/xep-0292.html) | None    | vCard4 Over XMPP |
[XEP-0293](http://xmpp.org/extensions/xep-0293.html) | None    | Jingle RTP Feedback Negotiation |
[XEP-0294](http://xmpp.org/extensions/xep-0294.html) | None    | Jingle RTP Header Extensions Negotiation |
[XEP-0295](http://xmpp.org/extensions/xep-0295.html) | None    | JSON Encodings for XMPP |
[XEP-0296](http://xmpp.org/extensions/xep-0296.html) | None    | Best Practices for Resource Locking |
[XEP-0297](http://xmpp.org/extensions/xep-0297.html) | None    | Stanza Forwarding |
[XEP-0298](http://xmpp.org/extensions/xep-0298.html) | None    | Delivering Conference Information to Jingle Participants (Coin) |
[XEP-0299](http://xmpp.org/extensions/xep-0299.html) | None    | Codecs for Jingle Video |
[XEP-0300](http://xmpp.org/extensions/xep-0300.html) | None    | Use of Cryptographic Hash Functions in XMPP |
[XEP-0301](http://xmpp.org/extensions/xep-0301.html) | None    | In-Band Real Time Text |
[XEP-0302](http://xmpp.org/extensions/xep-0302.html) | None    | XMPP Compliance Suites 2012 |
[XEP-0303](http://xmpp.org/extensions/xep-0303.html) | None    | Commenting |
[XEP-0304](http://xmpp.org/extensions/xep-0304.html) | None    | Whitespace Keepalive Negotiation |
[XEP-0305](http://xmpp.org/extensions/xep-0305.html) | None    | XMPP Quickstart |
[XEP-0306](http://xmpp.org/extensions/xep-0306.html) | None    | Extensible Status Conditions for Multi-User Chat |
[XEP-0307](http://xmpp.org/extensions/xep-0307.html) | None    | Unique Room Names for Multi-User Chat |
[XEP-0308](http://xmpp.org/extensions/xep-0308.html) | None    | Last Message Correction |
[XEP-0309](http://xmpp.org/extensions/xep-0309.html) | None    | Service Directories |
[XEP-0310](http://xmpp.org/extensions/xep-0310.html) | None    | Presence State Annotations |
[XEP-0311](http://xmpp.org/extensions/xep-0311.html) | None    | MUC Fast Reconnect |
[XEP-0312](http://xmpp.org/extensions/xep-0312.html) | None    | PubSub Since |


# Contributions

All contributions are welcome, even encouraged. However, contributions must be
well tested. If you send me a branch name to merge that'll get my attention faster
than a change set made directly on master.

# Author

* [Jeff Smick](http://github.com/sprsquish)
* [Other Contributors](https://github.com/adhearsion/blather/contributors)

# Copyright

Copyright (c) 2012 Adhearsion Foundation Inc. See LICENSE for details.
