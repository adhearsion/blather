# [develop](https://github.com/adhearsion/blather/compare/master...develop)
  * Bugfix: Handle stanzas with nested elements that don't have a decorator module or are not stanzas
  * Bugfix: Fix the roster which was broken by the DSL being included in Object

# [v0.8.6](https://github.com/adhearsion/blather/compare/v0.8.5...v0.8.6) - [2013-08-23](https://rubygems.org/gems/blather/versions/0.8.6)
  * Bugfix: Ensure that session creation always comes immediately after binding. Fixes incompatibility with ejabberd.
  * Bugfix: Close streams on next EM tick to avoid hanging.
  * Bugfix: Ensure handler methods are available even when including the DSL in Object

# [v0.8.5](https://github.com/adhearsion/blather/compare/v0.8.4...v0.8.5) - [2013-06-01](https://rubygems.org/gems/blather/versions/0.8.5)
  * Bugfix: Ensure that binding is always performed before session creation, regardless of the order of elements in the feature set provided by the server. This was causing incompatability with Tigase.

# [v0.8.4](https://github.com/adhearsion/blather/compare/v0.8.3...v0.8.4) - [2013-03-20](https://rubygems.org/gems/blather/versions/0.8.4)
  * Bugfix: Only finish stream parser if there is one. This prevents crashes on failure to connect.

# [v0.8.3](https://github.com/adhearsion/blather/compare/v0.8.2...v0.8.3) - [2013-03-03](https://rubygems.org/gems/blather/versions/0.8.3)
  * Bugfix: Strange issue causing total failure with 0.8.2 - https://github.com/adhearsion/blather/issues/108

# [v0.8.2](https://github.com/adhearsion/blather/compare/v0.8.1...v0.8.2) - [2013-01-02](https://rubygems.org/gems/blather/versions/0.8.2)
  * Bugfix: General spec fixes
  * Bugfix: Fixes for JRuby and Rubinius
  * Bugfix: Ensure parsers are shut down correctly
  * Update: Bump Nokogiri (1.5.6) and EventMachine (1.0.0) minimum versions

# [v0.8.1](https://github.com/adhearsion/blather/compare/v0.8.0...v0.8.1) - [2012-09-17](https://rubygems.org/gems/blather/versions/0.8.1)
  * Project moved to the Adhearsion Foundation
  * Fixes for EventMachine 1.0.x
  * Simplify booting client using the DSL in the varying supported modes
  * Documentation fixes

# [v0.8.0](https://github.com/adhearsion/blather/compare/v0.7.1...v0.8.0) - [2012-07-09](https://rubygems.org/gems/blather/versions/0.8.0)
  * Feature(jmkeys): DSL methods for joining and sending messages to MUC rooms
  * Feature(jackhong): Inband registration support
  * Bugfix(benlangfeld): Ensure that presence nodes which are both status and subscription may be responded to
  * Bugfix(benlangfeld): A whole bunch of JRuby fixes

# [v0.7.1](https://github.com/adhearsion/blather/compare/v0.7.0...v0.7.1) - [2012-04-29](https://rubygems.org/gems/blather/versions/0.7.1)
  * Documentation updates
  * Bugfix(benlangfeld): Relax Nokogiri dependency to allow 1.5
  * Bugfix(benlangfeld): Fix some nokogiri 1.5 related bugs on JRuby (some remain)
  * Bugfix(benlangfeld): Set namespaces correctly on some tricky nodes
  * Bugfix(benlangfeld): Ensure all presence sub-types trigger the correct handlers

# [v0.7.0](https://github.com/adhearsion/blather/compare/v0.6.2...v0.7.0) - [2012-03-15](https://rubygems.org/gems/blather/versions/0.7.0)
  * Change(benlangfeld): Drop Ruby 1.8.7 compatability
  * Change(bklang): Remove the wire log, which duplicated the parsed logging
  * Feature(benlangfeld): Stanza handlers are now executed outside of the EM reactor, so it is not blocked on stanza processing
  * Bugfix(benlangfeld): MUC user presence and messages now have separate handler names
  * Feature(benlangfeld): Stanzas may now be imported from a string using `XMPPNode.parse`
  * Bugfix(benlangfeld): All `Blather::Stanza::Presence::C` attributes are now accessible on importing
  * Bugfix(benlangfeld): Presence stanzas are now composed on import, including all children
  * Bugfix(mtrudel): JIDs in roster item stanzas are now stripped of resources

# [v0.6.2](https://github.com/adhearsion/blather/compare/v0.6.1...v0.6.2) - [2012-02-28](https://rubygems.org/gems/blather/versions/0.6.2)
  * Feature(benlangfeld): Add password support to `MUCUser`
  * Feature(benlangfeld): Add support for invitation elements to `MUCUser` messages
  * Feature(benlangfeld): Add support for MUC invite declines
  * Bugfix(benlangfeld): Don't implicitly create an invite node when checking invite status
  * Bugfix(benlangfeld): Ensure that form nodes are not duplicated on muc/muc_user presence stanzas

# [v0.6.1](https://github.com/adhearsion/blather/compare/v0.6.0...v0.6.1) - [2012-02-25](https://rubygems.org/gems/blather/versions/0.6.1)
  * Bugfix(benlangfeld): Ensure MUC presence nodes (joining) have a form element on creation

# [v0.6.0](https://github.com/adhearsion/blather/compare/v0.5.12...v0.6.0) - [2012-02-24](https://rubygems.org/gems/blather/versions/0.6.0)
  * Feature(benlangfeld): Very basic MUC and delayed message support
  * Bugfix(theozaurus): Disable connection timeout timer if client deliberately disconnects
  * Bugfix(mtrudel): Fix `Roster#each` to return roster_items as per documentation

# [v0.5.12](https://github.com/adhearsion/blather/compare/v0.5.11...v0.5.12) - [2012-01-06](https://rubygems.org/gems/blather/versions/0.5.12)
  * Bugfix(benlangfeld): Allow specifying the connection timeout in DSL setup

# [v0.5.11](https://github.com/adhearsion/blather/compare/v0.5.10...v0.5.11) - [2012-01-06](https://rubygems.org/gems/blather/versions/0.5.11)
  * Feature(benlangfeld): Allow specifying a connection timeout
    * Raise `Blather::Stream::ConnectionTimeout` if timeout is exceeded
    * Default to 180 seconds

# [v0.5.10](https://github.com/adhearsion/blather/compare/v0.5.9...v0.5.10) - [2011-12-02](https://rubygems.org/gems/blather/versions/0.5.10)
  * Feature(juandebravo): Allow configuring the wire log level
  * Bugfix(benlangfeld): Checking connection status before the stream is established

# [v0.5.9](https://github.com/adhearsion/blather/compare/v0.5.8...v0.5.9) - [2011-11-24](https://rubygems.org/gems/blather/versions/0.5.9)
  * Bugfix(benlangfeld): Failed connections now raise a Blather::Stream::ConnectionFailed exception
  * Bugfix(crohr): Blather now supports EventMachine 1.0

# v0.5.8
  * Bugfix(benlangfeld): JIDs now maintain case, but still compare case insensitively
  * Bugfix(jmazzi): Development dependencies now resolve correctly on JRuby and Rubinius

# v0.5.7
  * Bugfix(benlangfeld): Don't install BlueCloth as a development dependency when on JRuby

# v0.5.6
  * Changes from 0.5.5, this time without a bug when using the namespaced DSL approach

# v0.5.5 (yanked)
  * Bugfix(benlangfeld/kibs): ActiveSupport was overriding the presence DSL method
  * Feature(fyafighter): Adds SSL peer verification to TLS

# v0.5.4
  * Bugfix(fyafighter): Regression related to earlier refactoring: https://github.com/sprsquish/blather/issues/53
  * Feature(fyafighter): Make it much easier to allow private network addresses
  * Bugfix(benlangfeld): Fix the Nokogiri dependency to the 1.4.x series, due to a bug in 1.5.x
  * Bugfix(zlu): Replace class_inheritable_attribute with class_attribute because it is deprecated in ActiveSupport 3.1

# v0.5.3
  * Feature(benlangfeld): Add XMPP Ping (XEP-0199) support

# v0.5.2
  * Bugfix(benlangfeld): Remove specs for the Nokogiri extensions which were moved out

# v0.5.1 - yanked
  * Feature(benlangfeld): Abstract out Nokogiri extensions and helpers into new Niceogiri gem for better sharing
  * Documentation(benlangfeld)

# v0.5.0
  * Feature(radsaq): Add a #connected? method on Blather::Client
  * Feature(benlangfeld)[API change]: Allow the removal of child nodes from an IQ reply
  * Bugfix(zlu): Use rubygems properly in examples
  * Bugfix(benlangfeld): Remove code borrowed from ActiveSupport and instead depend on it to avoid version conflicts
  * Documentation(sprsquish)

# v0.4.16
  * Feature(benlangfeld): switch from jeweler to bundler
  * Feature(benlangfeld): add cap support (XEP-0115)
  * Bugfix(sprsquish): Better equality checking
  * Bugfix(sprsquish): Fix #to_proc
  * Bugfix(mironov): Skip private IPs by default

# v0.4.15
  * Feature(mironov): Implement XEP-0054: vcard-temp
  * Feature(benlangfeld): Basic support for PubSub subscription notifications as PubSub events
  * Feature(mironov): Ability to clear handlers
  * Feature(mironov): Implement incoming file transfers (XEP-0096, XEP-0065, XEP-0047)
  * Bugfix(mironov): Fix for importing messages with chat states
  * Bugfix(mironov): Added Symbol#to_proc method to work on ruby 1.8.6
  * Bugfix(mironov): Fix roster items .status method to return highest priority presence
  * Bugfix(mironov): Remove old unavailable presences while adding new one
  * Bugfix(mironov): Use Nokogiri::XML::ParseOptions::NOENT to prevent double-encoding of entities
  * Bugfix(benlangfeld): Disco Info Identities should have an xml:lang attribute
  * Bugfix(mironov): Fix lookup path for ruby 1.9
  * Bugfix(mironov): stanza_error.to_node must set type of the error
  * Bugfix(mironov): Allow message to have iq child
  * Bugfix(mironov): Find xhtml body in messages sent from iChat 5.0.3

# v0.4.14
  * Tests: get specs fully passing on rubinius
  * Feature(mironov): Implement XEP-0085 Chat State Notifications
  * Bugfix(mironov): send stanzas unformatted
  * Bugfix(mironov): Message#xhtml uses inner_html so tags aren't escaped
  * Bugfix(mironov): Message#xhtml= now works with multiple root nodes

# v0.4.13
  * Bugfix: Place form child of command inside command element

# v0.4.12
  * API Change: Switch order of var and type arguments to X::Field.new since var is always required but type is not
  * API Change: PubSub payloads can be strings or nodes and can be set nil. PubSub#payload will always return a string
  * Feature: Add forms to Message stanzas

# v0.4.11
  * Bugfix: command nodes where generating the wrong xml
  * Bugfix: x nodes where generating the wrong xml
  * Feature: ability to set identities and features on disco info nodes
  * Feature: ability to set items on disco item nodes

# v0.4.10
  * no change

# v0.4.9
  * Feature: XEP-0004 x:data (benlangfeld)
  * Feature: XEP-0050 Ad-Hoc commands (benlangfeld)
  * Minor bugfixes for the specs

# v0.4.8
  * Feature: add xhtml getter/setter to Message stanza
  * Bugfix: heirarchy -> hierarchy spelling mistake
  * Hella documentation

# v0.4.7
  * Update to work with Nokogiri 1.4.0

# v0.4.6
  * Bugfix: prioritize authentication mechanisms

# v0.4.5
  * Bugfix: Change DSL#write to DSL#write_to_stream. Previous way was messing with YAML

# v0.4.4
  * Add "disconnected" handler type to handle connection termination
  * Bugfix: Fix error with pubsub using the wrong client connection

# v0.4.3
  * Bugfix: status stanza with a blank state will be considered :available (GH-23)
  * Bugfix: ensure regexp guards try to match against a string (GH-24)
  * Stream creation is now evented. The stream object will be sent to #post_init
  * Parser debugging disabled by default
  * Update parser to work with Nokogiri 1.3.2
  * Bugfix: discover helper now calls the correct method on client
  * Bugfix: ensure XMPPNode#inherit properly sets namespaces on inherited nodes
  * Bugfix: xpath guards with namespaces work properly (GH-25)

# v0.4.2
  * Fix -D option to actually put Blather in debug mode
  * Stanzas over a client connection will either have the full JID or no JID
  * Regexp guards can be anything that implements #last_match (Regexp or Oniguruma)
  * Add "halt" and "pass" to allow handlers to either halt the handler chain or pass to the next handler
  * Fix default status handler so it doesn't eat the stanza
  * Add before and after filters. Filters, like handlers, can have guards.

# v0.4.1
  * Bugfix in roster: trying to call the wrong method on client

# v0.4.0
  * Switch from LibXML-Ruby to Nokogiri
  * Update test suite to run on Ruby 1.9
  * Add "<<" style writer to the DSL to provide for chaining outbound writes
  * SRV lookup support
  * Add XPath type of handler guard
  * PubSub support

# v0.3.4
  * Remove unneeded functions from the push parser.
  * Create a ParseWarning error that doesn't kill the stream.
  * When a parse error comes in the reply should let the other side know it screwed up before dying.
  * Add the LibXML::XML::Error node to the ParseError/ParseWarning objects.

# v0.3.3
  * Fix the load error related to not pushing Blather's dir into the load path

# v0.3.2
  * Switch the push parser from chunking to streaming.
  * Don't push Blather's dir into the load paths

# v0.3.1
  * Small changes to the DSL due to handler collisions:
    "status" -> "set_status"
    "roster" -> "my_roster"
  * Small changes to the Blather::Client API to keep it feeling more like EM's API:
    #stream_started -> #post_init
    #call -> #receive_data
    #stop -> #close
    #stopped -> #unbind
  * Refactored some of the code internal to Blather::Client
  * Added command line option handler to default use method (see README)
  * require libxml-ruby >=1.1.2 (1.1.3 has an inconsistent malloc err on OS X 10.5)
  * complete specs
  * add single process ping-pong example

# v0.3.0
  * Remove autotest discover.rb (created all sorts of conflicts)
  * Added Hash with Array guard
  * Added a hirrarchy printer to examples directory
  * Moved Disco to be in the Stanza namespace (staves off deeply namespaced classes)
  * Namespaced the DSL methods to Blather::DSL. These can be included in any object you like now. "require 'blather/client'" will still include them directly in Kernel to keep the simple one-file dsl
  * Stopped doing one class per error type. This created a giant hierarchy tree that was just unnecessary. The error name is now #name. Errors can be matched with a combination of handler and guard.
  * Fixed XML namespaces. Previous versions weren't actually adding the node to the namespace making xpath queries inconsistent at best.
  * Added support for anonymous authentication by providing a blank node on the jid ("@[host]")

# v0.2.3
  * Go back to using the master branch for gems (stupid mistake)

# v0.2.2
  * Switch to Jeweler.
  * Move from custom libxml to just a custom push parser
  * Add guards to handlers

# v0.2.1 Upgrade to libxml 0.9.7

# v0.2 Overhaul the DSL to look more like Sinatra

# v0.1 Initial release (birth!)
