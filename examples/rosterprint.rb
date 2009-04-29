#!/usr/bin/env ruby

# Prints out each roster entry

require 'blather/client'

when_ready do
  roster.grouped.each do |group, items|
    puts "#{'*'*3} #{group || 'Ungrouped'} #{'*'*3}"
    items.each { |item| puts "- #{item.name} (#{item.jid})" }
    puts
  end
  shutdown
end
