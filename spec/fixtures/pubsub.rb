def items_all_nodes_xml
<<-ITEMS
<iq type='result'
    from='pubsub.shakespeare.lit'
    to='francisco@denmark.lit/barracks'
    id='items1'>
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    <items node='princely_musings'>
      <item id='368866411b877c30064a5f62b917cffe'>
        <entry xmlns='http://www.w3.org/2005/Atom'>
          <title>The Uses of This World</title>
          <summary>
O, that this too too solid flesh would melt
Thaw and resolve itself into a dew!
          </summary>
          <link rel='alternate' type='text/html'
                href='http://denmark.lit/2003/12/13/atom03'/>
          <id>tag:denmark.lit,2003:entry-32396</id>
          <published>2003-12-12T17:47:23Z</published>
          <updated>2003-12-12T17:47:23Z</updated>
        </entry>
      </item>
      <item id='3300659945416e274474e469a1f0154c'>
        <entry xmlns='http://www.w3.org/2005/Atom'>
          <title>Ghostly Encounters</title>
          <summary>
O all you host of heaven! O earth! what else?
And shall I couple hell? O, fie! Hold, hold, my heart;
And you, my sinews, grow not instant old,
But bear me stiffly up. Remember thee!
          </summary>
          <link rel='alternate' type='text/html'
                href='http://denmark.lit/2003/12/13/atom03'/>
          <id>tag:denmark.lit,2003:entry-32396</id>
          <published>2003-12-12T23:21:34Z</published>
          <updated>2003-12-12T23:21:34Z</updated>
        </entry>
      </item>
      <item id='4e30f35051b7b8b42abe083742187228'>
        <entry xmlns='http://www.w3.org/2005/Atom'>
          <title>Alone</title>
          <summary>
Now I am alone.
O, what a rogue and peasant slave am I!
          </summary>
          <link rel='alternate' type='text/html'
                href='http://denmark.lit/2003/12/13/atom03'/>
          <id>tag:denmark.lit,2003:entry-32396</id>
          <published>2003-12-13T11:09:53Z</published>
          <updated>2003-12-13T11:09:53Z</updated>
        </entry>
      </item>
      <item id='ae890ac52d0df67ed7cfdf51b644e901'>
        <entry xmlns='http://www.w3.org/2005/Atom'>
          <title>Soliloquy</title>
          <summary>
To be, or not to be: that is the question:
Whether 'tis nobler in the mind to suffer
The slings and arrows of outrageous fortune,
Or to take arms against a sea of troubles,
And by opposing end them?
          </summary>
          <link rel='alternate' type='text/html'
                href='http://denmark.lit/2003/12/13/atom03'/>
          <id>tag:denmark.lit,2003:entry-32397</id>
          <published>2003-12-13T18:30:02Z</published>
          <updated>2003-12-13T18:30:02Z</updated>
        </entry>
      </item>
    </items>
  </pubsub>
</iq>
ITEMS
end

def pubsub_items_some_xml
<<-ITEMS
<iq type='result'
    from='pubsub.shakespeare.lit'
    to='francisco@denmark.lit/barracks'
    id='items1'>
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    <items node='princely_musings'>
      <item id='368866411b877c30064a5f62b917cffe'>
        <entry xmlns='http://www.w3.org/2005/Atom'>
          <title>The Uses of This World</title>
          <summary>
O, that this too too solid flesh would melt
Thaw and resolve itself into a dew!
          </summary>
          <link rel='alternate' type='text/html'
                href='http://denmark.lit/2003/12/13/atom03'/>
          <id>tag:denmark.lit,2003:entry-32396</id>
          <published>2003-12-12T17:47:23Z</published>
          <updated>2003-12-12T17:47:23Z</updated>
        </entry>
      </item>
      <item id='3300659945416e274474e469a1f0154c'>
        <entry xmlns='http://www.w3.org/2005/Atom'>
          <title>Ghostly Encounters</title>
          <summary>
O all you host of heaven! O earth! what else?
And shall I couple hell? O, fie! Hold, hold, my heart;
And you, my sinews, grow not instant old,
But bear me stiffly up. Remember thee!
          </summary>
          <link rel='alternate' type='text/html'
                href='http://denmark.lit/2003/12/13/atom03'/>
          <id>tag:denmark.lit,2003:entry-32396</id>
          <published>2003-12-12T23:21:34Z</published>
          <updated>2003-12-12T23:21:34Z</updated>
        </entry>
      </item>
      <item id='4e30f35051b7b8b42abe083742187228'>
        <entry xmlns='http://www.w3.org/2005/Atom'>
          <title>Alone</title>
          <summary>
Now I am alone.
O, what a rogue and peasant slave am I!
          </summary>
          <link rel='alternate' type='text/html'
                href='http://denmark.lit/2003/12/13/atom03'/>
          <id>tag:denmark.lit,2003:entry-32396</id>
          <published>2003-12-13T11:09:53Z</published>
          <updated>2003-12-13T11:09:53Z</updated>
        </entry>
      </item>
    </items>
    <set xmlns='http://jabber.org/protocol/rsm'>
      <first index='0'>368866411b877c30064a5f62b917cffe</first>
      <last>4e30f35051b7b8b42abe083742187228</last>
      <count>19</count>
    </set>
  </pubsub>
</iq>
ITEMS
end

def affiliations_xml
<<-NODE
<iq type='result'
    from='pubsub.shakespeare.lit'
    to='francisco@denmark.lit'
    id='affil1'>
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    <affiliations>
      <affiliation node='node1' affiliation='owner'/>
      <affiliation node='node2' affiliation='owner'/>
      <affiliation node='node3' affiliation='publisher'/>
      <affiliation node='node4' affiliation='outcast'/>
      <affiliation node='node5' affiliation='member'/>
      <affiliation node='node6' affiliation='none'/>
    </affiliations>
  </pubsub>
</iq>
NODE
end

def subscriptions_xml
<<-NODE
<iq type='result'
    from='pubsub.shakespeare.lit'
    to='francisco@denmark.lit'
    id='affil1'>
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    <subscriptions>
      <subscription node='node1' subscription='subscribed'/>
      <subscription node='node2' subscription='subscribed'/>
      <subscription node='node3' subscription='unconfigured'/>
      <subscription node='node4' subscription='pending'/>
      <subscription node='node5' subscription='none'/>
    </subscriptions>
  </pubsub>
</iq>
NODE
end

def event_with_payload_xml
<<-NODE
<message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
  <event xmlns='http://jabber.org/protocol/pubsub#event'>
    <items node='princely_musings'>
      <item id='ae890ac52d0df67ed7cfdf51b644e901'>
        <entry xmlns='http://www.w3.org/2005/Atom'>
          <title>Soliloquy</title>
          <summary>
To be, or not to be: that is the question:
Whether 'tis nobler in the mind to suffer
The slings and arrows of outrageous fortune,
Or to take arms against a sea of troubles,
And by opposing end them?
          </summary>
          <link rel='alternate' type='text/html'
                href='http://denmark.lit/2003/12/13/atom03'/>
          <id>tag:denmark.lit,2003:entry-32397</id>
          <published>2003-12-13T18:30:02Z</published>
          <updated>2003-12-13T18:30:02Z</updated>
        </entry>
      </item>
    </items>
  </event>
</message>
NODE
end

def event_notification_xml
<<-NODE
<message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
  <event xmlns='http://jabber.org/protocol/pubsub#event'>
    <items node='princely_musings'>
      <item id='ae890ac52d0df67ed7cfdf51b644e901'/>
    </items>
  </event>
</message>
NODE
end

def event_subids_xml
<<-NODE
<message from='pubsub.shakespeare.lit' to='francisco@denmark.lit' id='foo'>
  <event xmlns='http://jabber.org/protocol/pubsub#event'>
    <items node='princely_musings'>
      <item id='ae890ac52d0df67ed7cfdf51b644e901'/>
    </items>
  </event>
  <headers xmlns='http://jabber.org/protocol/shim'>
    <header name='SubID'>123-abc</header>
    <header name='SubID'>004-yyy</header>
  </headers>
</message>
NODE
end

def unsubscribe_xml
<<-NODE
<iq type='error'
    from='pubsub.shakespeare.lit'
    to='francisco@denmark.lit/barracks'
    id='unsub1'>
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
     <unsubscribe node='princely_musings' jid='francisco@denmark.lit'/>
  </pubsub>
  <error type='modify'>
    <bad-request xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
    <subid-required xmlns='http://jabber.org/protocol/pubsub#errors'/>
  </error>
</iq>
NODE
end

def subscriber_xml
<<-NODE
<iq type='result'
    from='pubsub.shakespeare.lit'
    to='francisco@denmark.lit/barracks'
    id='sub1'>
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    <subscription
        node='princely_musings'
        jid='francisco@denmark.lit'
        subid='ba49252aaa4f5d320c24d3766f0bdcade78c78d3'
        subscription='subscribed'/>
  </pubsub>
</iq>
NODE
end

def publish_xml
<<-NODE
<iq type='result'
    from='pubsub.shakespeare.lit'
    to='hamlet@denmark.lit/blogbot'
    id='publish1'>
  <pubsub xmlns='http://jabber.org/protocol/pubsub'>
    <publish node='princely_musings'>
      <item id='ae890ac52d0df67ed7cfdf51b644e901'/>
    </publish>
  </pubsub>
</iq>
NODE
end