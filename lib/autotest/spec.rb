require 'autotest'

Autotest.add_hook :initialize do |at|
  at.clear_mappings
  # watch out: Ruby bug (1.8.6):
  # %r(/) != /\//
  at.add_mapping(%r%^spec/.*_spec.rb$%) { |filename, _|
    filename
  }
  at.add_mapping(%r%^lib/(.*)\.rb$%) { |_, m|
    ["spec/#{m[1]}_spec.rb"]
  }
  at.add_mapping(%r%^spec/(spec_helper|shared/.*)\.rb$%) { 
    at.files_matching %r%^spec/.*_spec\.rb$%
  }
end

BAR       = "=" * 78
REDCODE   = 31
GREENCODE = 32

Autotest.add_hook :ran_command do |at|
  at.results.last =~ /^.* (\d+) failures, (\d+) errors/

  code = ($1 == "0" and $2 == "0") ? GREENCODE : REDCODE
  puts "\e[#{ code }m#{ BAR }\e[0m\n\n"
end

class Autotest::Spec < Autotest
  def path_to_classname(s)
    sep = File::SEPARATOR
    f = s.sub(/spec#{sep}/, '').sub(/(spec)?\.rb$/, '').split(sep)
    f = f.map { |path| path.split(/_|(\d+)/).map { |seg| seg.capitalize }.join }
    f = f.delete_if { |path| path == 'Core' }
    f.join
  end

  ##
  # Returns a hash mapping a file name to the known failures for that
  # file.

  def consolidate_failures(failed)
    filters = new_hash_of_arrays

    class_map = Hash[*self.find_order.grep(/^spec/).map { |f| # TODO: ugly
                       [path_to_classname(f), f]
                     }.flatten]
    class_map.merge!(self.extra_class_map)

    failed.each do |method, klass|
      if class_map.has_key? klass then
        filters[class_map[klass]] << method
      else
        output.puts "Unable to map class #{klass} to a file"
      end
    end

    return filters
  end
end
