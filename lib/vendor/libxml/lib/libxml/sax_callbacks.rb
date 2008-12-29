module LibXML
  module XML
    class SaxParser
      module Callbacks
        # Called for a CDATA block event.
        def on_cdata_block(cdata)
        end

        # Called for a characters event.
        def on_characters(chars)
        end

        # Called for a comment event.
        def on_comment(msg)
        end

        # Called for a end document event.
        def on_end_document
        end

        # Called for a end element event.
        def on_end_element_ns(name, prefix, uri)
        end

        # Called for parser errors.
        def on_error(msg)
        end

        # Called for an external subset event.
        def on_external_subset(name, external_id, system_id)
        end

        # Called for an external subset notification event.
        def on_has_external_subset
        end

        # Called for an internal subset notification event.
        def on_has_internal_subset
        end

        # Called for an internal subset event.
        def on_internal_subset(name, external_id, system_id)
        end

        # Called for 'is standalone' event.
        def on_is_standalone
        end

        # Called for an processing instruction event.
        def on_processing_instruction(target, data)
        end

        # Called for a reference event.
        def on_reference(name)
        end

        # Called for a start document event.
        def on_start_document
        end

        # Called for a start element event.
        def on_start_element_ns(name, attributes, prefix, uri, namespaces)
        end
      end

      module VerboseCallbacks
        # Called for a CDATA block event.
        def on_cdata_block(cdata)
          STDOUT << "on_cdata_block(" << cdata << ")\n"
          STDOUT.flush
        end

        # Called for a characters event.
        def on_characters(chars)
          STDOUT << "on_characters(" << chars << ")\n"
          STDOUT.flush
        end

        # Called for a comment event.
        def on_comment(msg)
          STDOUT << "on_comment(" << msg << ")\n"
          STDOUT.flush
        end

        # Called for a end document event.
        def on_end_document
          STDOUT << "on_end_document\n"
          STDOUT.flush
        end

        # Called for a end element event.
        def on_end_element_ns(name, prefix, uri)
          STDOUT << "on_end_element(" << name <<
                                      ", prefix: " << prefix << 
                                      ", uri: " << uri <<
                                      ")\n"
          STDOUT.flush
        end

        # Called for parser errors.
        def on_error(error)
          STDOUT << "on_error(" << error << ")\n"
          STDOUT.flush
        end

        # Called for an external subset event.
        def on_external_subset(name, external_id, system_id)
          STDOUT << "on_external_subset(" << name << ", " << external_id << ", " << system_id << ")\n"
          STDOUT.flush
        end

        # Called for an external subset notification event.
        def on_has_external_subset
          STDOUT << "on_has_internal_subset\n"
          STDOUT.flush
        end

        # Called for an internal subset notification event.
        def on_has_internal_subset
          STDOUT << "on_has_internal_subset\n"
          STDOUT.flush
        end

        # Called for an internal subset event.
        def on_internal_subset(name, external_id, system_id)
          STDOUT << "on_internal_subset(" << name << ", " << external_id << ", " << system_id << ")\n"
          STDOUT.flush
        end

        # Called for 'is standalone' event.
        def on_is_standalone
          STDOUT << "on_is_standalone\n"
          STDOUT.flush
        end

        # Called for an processing instruction event.
        def on_processing_instruction(target, data)
          STDOUT << "on_characters(" << target << ", " << data << ")\n"
          STDOUT.flush
        end

        # Called for a reference event.
        def on_reference(name)
          STDOUT << "on_reference(" << name << ")\n"
          STDOUT.flush
        end

        # Called for a start document event.
        def on_start_document
          STDOUT << "on_start_document\n"
          STDOUT.flush
        end

        # Called for a start element event.
        def on_start_element_ns(name, attributes, prefix, uri, namespaces)
          STDOUT << "on_start_element_ns(" << name <<
                                      ", attr " << (attributes || Hash.new).inspect <<
                                      ", prefix: " << prefix <<
                                      ", uri: " << uri << ")\n" <<
                                      ", ns " << (namespaces || Hash.new).inspect <<
                                      ")\n"
          STDOUT.flush
        end
      end
    end
  end
end