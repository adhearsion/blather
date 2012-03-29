# Blather [ ![Build status](http://travis-ci.org/sprsquish/blather.png) ](http://travis-ci.org/sprsquish/blather)

XMPP DSL (and more) for Ruby written on [EventMachine](http://rubyeventmachine.com/) and [Nokogiri](http://nokogiri.org/).

## Features

* evented architecture
* uses Nokogiri
* simplified starting point

## Project Pages

* [GitHub](https://github.com/sprsquish/blather)
* [Gemcutter](http://gemcutter.org/gems/blather)
* [API Documentation](http://rdoc.info/gems/blather/file/README.md)
* [Google Group](http://groups.google.com/group/xmpp-blather)

# Usage

## Installation

    gem install blather

## Example

Blather comes with a DSL that makes writing XMPP bots quick and easy. See the examples directory for more advanced examples.

```ruby
require 'rubygems'
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

## On the Command Line:

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

## Health warning:

Some parts of Blather will allow you to do stupid things that don't conform to XMPP
spec. You should exercise caution and read the relevant specifications (indicated in
the preamble to most relevant classes).

# Contributions

All contributions are welcome, even encouraged. However, contributions must be
well tested. If you send me a branch name to merge that'll get my attention faster
than a change set made directly on master.

# Author

* [Jeff Smick](http://github.com/sprsquish)
* [Other Contributors](https://github.com/sprsquish/blather/contributors)

# Copyright

Copyright (c) 2012 Jeff Smick. See LICENSE for details.
