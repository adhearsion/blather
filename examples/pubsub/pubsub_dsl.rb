# Get affiliations
pubsub.affiliations do |aff|
  aff == {
    :member     => [],
    :none       => [],
    :outcast    => [],
    :owner      => [],
    :publisher  => []
  }
end

# Get subscriptions
pubsub.subscriptions do |sub|
  sub == {
    :none         => [],
    :pending      => [],
    :subscribed   => [],
    :unconfigured => []
  }
end

# Get nodes
pubsub.nodes(path = nil) do |nodes|
  nodes == [
    DiscoItems::Item
      .jid
      .node
      .name
  ]
end

# Get node
pubsub.node(path = nil) do |node|
  node = Node
    .attributes = {
      [form data fields]
    }
    .type = '(leaf|collection)'
    .feature = ''
    .items(ids = [], :max => nil) { |list_of_items| }
end

# Get node items
pubsub.items(path = '' | ids = [], max = nil) do |node_items|
  node_items = [
    Item
      .jid
      .id
      .name
      .payload
  ]
end
