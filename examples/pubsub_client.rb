# For subscribers
  pubsub.nodes [path]
  pubsub.node('path')
  pubsub.node('path').subscribe
  pubsub.node('path').affiliation
# For owners
  pubsub.node('path').affiliations
  pubsub.node('path').delete!
  pubsub.node('path').purge!
  pubsub.node('path').options
  pubsub.node('path').defaults
  pubsub.node('path').configure {}

pubsub.affiliations

pubsub.create 'node'

pubsub.publish 'node', 'content'
pubsub.delete 'node', 'item_id'

pubsub.subscriptions
pubsub.subscribe 'node'
pubsub.unsubscribe 'node'

# For subscribers
  pubsub.subscriptions 'node'
  pubsub.subscription 'node', [sub_id]
  pubsub.subscription('node', [sub_id]).unsubscribe!
  pubsub.subscription('node', [sub_id]).options
  pubsub.subscription('node', [sub_id]).configure 'node', {}
# For owners
  pubsub.subscriptions.pending
  pubsub.subscription('sub_id').delete!
  

Node::Collection
  nodes
Node::Leaf
  items