module Blather
class Stanza

  # # Capabilities Stanza
  #
  # [XEP-0115 Entity Capabilities](http://xmpp.org/extensions/xep-0115.html)
  #
  # XMPP protocol extension for broadcasting and dynamically discovering client, device, or generic entity capabilities.
  #
  class Capabilities < Blather::Stanza::DiscoInfo
    def self.new
      super :result
    end

    # A string that is used to verify the identity and supported features of the entity.
    #
    # @return [String]
    def ver
      generate_ver identities, features
    end

    # A URI that uniquely identifies a software application, typically a URL at the
    # website of the project or company that produces the software.
    #
    # @param [String] node the node URI
    def node=(node)
      @bare_node = node
      super "#{node}##{ver}"
    end

    # Add an array of identities
    # @param identities the array of identities, passed directly to Identity.new
    def identities=(identities)
      super identities
      regenerate_full_node
    end

    # Add an array of features
    # @param features the array of features, passed directly to Feature.new
    def features=(features)
      super features
      regenerate_full_node
    end

    # The generated Presence::C node
    #
    # @return [Blather::Stanza::Presence::C]
    def c
      Blather::Stanza::Presence::C.new @bare_node, ver
    end

    private

    def regenerate_full_node
      self.node = @bare_node
    end

    def generate_ver_str(identities, features, forms = [])
      # 1.  Initialize an empty string S.
      s = ''

      # 2. Sort the service discovery identities by category and
      # then by type (if it exists) and then by xml:lang (if it
      # exists), formatted as CATEGORY '/' [TYPE] '/' [LANG] '/'
      # [NAME]. Note that each slash is included even if the TYPE,
      # LANG, or NAME is not included.
      identities.sort! do |identity1, identity2|
        cmp_result = nil
        [:category, :type, :xml_lang, :name].each do |field|
          value1 = identity1.send(field)
          value2 = identity2.send(field)

          if value1 != value2
            cmp_result = value1 <=> value2
            break
          end
        end
        cmp_result
      end

      # 3. For each identity, append the 'category/type/lang/name' to
      # S, followed by the '<' character.
      s += identities.collect do |identity|
        [:category, :type, :xml_lang, :name].collect do |field|
          identity.send(field).to_s
        end.join('/') + '<'
      end.join

      # 4. Sort the supported service discovery features.
      features.sort! { |feature1, feature2| feature1.var <=> feature2.var }

      # 5. For each feature, append the feature to S, followed by the
      # '<' character.
      s += features.collect { |feature| feature.var.to_s + '<' }.join

      # 6. If the service discovery information response includes
      # XEP-0128 data forms, sort the forms by the FORM_TYPE (i.e., by
      # the XML character data of the <value/> element).
      forms.sort! do |form1, form2|
        fform_type1 = form1.field 'FORM_TYPE'
        fform_type2 = form2.field 'FORM_TYPE'
        form_type1 = fform_type1 ? fform_type1.values.to_s : nil
        form_type2 = fform_type2 ? fform_type2.values.to_s : nil
        form_type1 <=> form_type2
      end

      # 7. For each extended service discovery information form:
      forms.each do |form|
        # 7.1. Append the XML character data of the FORM_TYPE field's
        # <value/> element, followed by the '<' character.
        fform_type = form.field 'FORM_TYPE'
        form_type = fform_type ? fform_type.values.to_s : nil
        s += "#{form_type}<"

        # 7.2. Sort the fields by the value of the "var" attribute
        fields = form.fields.sort { |field1, field2| field1.var <=> field2.var }

        # 7.3. For each field:
        fields.each do |field|
          # 7.3.1. Append the value of the "var" attribute, followed by
          # the '<' character.
          s += "#{field.var}<"

          # 7.3.2. Sort values by the XML character data of the <value/> element
          # values = field.values.sort { |value1, value2| value1 <=> value2 }

          # 7.3.3. For each <value/> element, append the XML character
          # data, followed by the '<' character.
          # s += values.collect { |value| "#{value}<" }.join
          s += "#{field.value}<"
        end
      end
      s
    end

    def generate_ver(identities, features, forms = [], hash = 'sha-1')
      s = generate_ver_str identities, features, forms

      # 9. Compute the verification string by hashing S using the
      # algorithm specified in the 'hash' attribute (e.g., SHA-1 as
      # defined in RFC 3174). The hashed data MUST be generated
      # with binary output and encoded using Base64 as specified in
      # Section 4 of RFC 4648 (note: the Base64 output MUST NOT
      # include whitespace and MUST set padding bits to zero).

      # See http://www.iana.org/assignments/hash-function-text-names
      hash_klass = case hash
                     when 'md2' then nil
                     when 'md5' then Digest::MD5
                     when 'sha-1' then Digest::SHA1
                     when 'sha-224' then nil
                     when 'sha-256' then Digest::SHA256
                     when 'sha-384' then Digest::SHA384
                     when 'sha-512' then Digest::SHA512
                   end
      hash_klass ? [hash_klass::digest(s)].pack('m').strip : nil
    end
  end # Caps

end # Stanza
end # Blather
