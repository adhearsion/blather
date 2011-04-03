require 'spec_helper'

def x_xml
  <<-XML
  <x xmlns='jabber:x:data'
     type='form'>
    <title/>
    <instructions/>
    <field var='field-name'
           type='text-single'
           label='description' />
    <field var='field-name2'
           type='text-single'
           label='description' />
    <field var='field-name3'
           type='text-single'
           label='description' />
    <field var='field-name4'
           type='list-multi'
           label='description'>
      <desc/>
      <required/>
      <value>field-value4</value>
      <option label='option-label'><value>option-value</value></option>
      <option label='option-label'><value>option-value</value></option>
    </field>
  </x>
  XML
end

describe Blather::Stanza::X do

  it 'can be created from an XML string' do
    x = Blather::Stanza::X.new parse_stanza(x_xml).root
    x.type.must_equal :form
    x.must_be_instance_of Blather::Stanza::X
  end

  [:cancel, :form, :result, :submit].each do |type|
    it "type can be set as \"#{type}\"" do
      x = Blather::Stanza::X.new type
      x.type.must_equal type
    end
  end

  it 'is constructed properly' do
    n = Blather::Stanza::X.new :form
    n.find("/ns:x[@type='form']", :ns => Blather::Stanza::X.registered_ns).wont_be_empty
  end

  it 'has an action attribute' do
    n = Blather::Stanza::X.new :form
    n.type.must_equal :form
    n.type = :submit
    n.type.must_equal :submit
  end

  it 'has a title attribute' do
    n = Blather::Stanza::X.new :form
    n.title.must_equal nil
    n.title = "Hello World!"
    n.title.must_equal "Hello World!"
    n.title = "goodbye"
    n.title.must_equal "goodbye"
  end

  it 'has an instructions attribute' do
    n = Blather::Stanza::X.new :form
    n.instructions.must_equal nil
    n.instructions = "Please fill in this form"
    n.instructions.must_equal "Please fill in this form"
    n.instructions = "goodbye"
    n.instructions.must_equal "goodbye"
  end

  it 'inherits a list of fields' do
    n = Blather::Stanza::Iq::Command.new
    n.command << parse_stanza(x_xml).root
    r = Blather::Stanza::X.new.inherit n.form
    r.fields.size.must_equal 4
    r.fields.map { |f| f.class }.uniq.must_equal [Blather::Stanza::X::Field]
  end

  it 'returns a field object for a particular var' do
    x = Blather::Stanza::X.new parse_stanza(x_xml).root
    f = x.field 'field-name4'
    f.must_be_instance_of Blather::Stanza::X::Field
    f.value.must_equal 'field-value4'
  end

  it 'takes a list of hashes for fields' do
    fields = [
      {:label => 'label', :type => 'text-single', :var => 'var'},
      {:label => 'label1', :type => 'text-single', :var => 'var1'},
    ]

    control = [ Blather::Stanza::X::Field.new(*%w[var text-single label]),
                Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]

    di = Blather::Stanza::X.new nil, fields
    di.fields.size.must_equal 2
    di.fields.each { |f| control.include?(f).must_equal true }
  end

  it 'takes a list of Field objects as fields' do
    control = [ Blather::Stanza::X::Field.new(*%w[var text-single label1]),
                Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]

    di = Blather::Stanza::X.new nil, control
    di.fields.size.must_equal 2
    di.fields.each { |f| control.include?(f).must_equal true }
  end

  it 'takes a mix of hashes and field objects as fields' do
    fields = [
      {:label => 'label', :type => 'text-single', :var => 'var'},
      Blather::Stanza::X::Field.new(*%w[var1 text-single label1]),
    ]

    control = [ Blather::Stanza::X::Field.new(*%w[var text-single label]),
                Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]

    di = Blather::Stanza::X.new nil, fields
    di.fields.size.must_equal 2
    di.fields.each { |f| control.include?(f).must_equal true }
  end

  it 'allows adding of fields' do
    di = Blather::Stanza::X.new nil
    di.fields.size.must_equal 0
    di.fields = [{:label => 'label', :type => 'text-single', :var => 'var', :required => true}]
    di.fields.size.must_equal 1
    di.fields += [Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]
    di.fields.size.must_equal 2
  end

end

describe Blather::Stanza::X::Field do
  it 'will auto-inherit nodes' do
    n = parse_stanza "<field type='text-single' var='music' label='Music from the time of Shakespeare' />"
    i = Blather::Stanza::X::Field.new n.root
    i.type.must_equal 'text-single'
    i.var.must_equal 'music'
    i.label.must_equal 'Music from the time of Shakespeare'
  end

  it 'has a type attribute' do
    n = Blather::Stanza::X::Field.new 'var', 'text-single'
    n.type.must_equal 'text-single'
    n.type = 'hidden'
    n.type.must_equal 'hidden'
  end

  it 'has a var attribute' do
    n = Blather::Stanza::X::Field.new 'name', 'text-single'
    n.var.must_equal 'name'
    n.var = 'email'
    n.var.must_equal 'email'
  end

  it 'has a label attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    n.label.must_equal 'Music from the time of Shakespeare'
    n.label = 'Books by and about Shakespeare'
    n.label.must_equal 'Books by and about Shakespeare'
  end

  it 'has a desc attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    n.desc.must_equal nil
    n.desc = 'Books by and about Shakespeare'
    n.desc.must_equal 'Books by and about Shakespeare'
    n.desc = 'goodbye'
    n.desc.must_equal 'goodbye'
  end

  it 'has a required? attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    n.required?.must_equal false
    n.required = true
    n.required?.must_equal true
    n.required = false
    n.required?.must_equal false
  end

  it 'has a value attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    n.value.must_equal nil
    n.value = 'book1'
    n.value.must_equal 'book1'
    n.value = 'book2'
    n.value.must_equal 'book2'
  end

  # Option child elements
  it 'allows adding of options' do
    di = Blather::Stanza::X::Field.new nil
    di.options.size.must_equal 0
    di.options += [{:label => 'Person', :value => 'person'}]
    di.options.size.must_equal 1
    di.options += [Blather::Stanza::X::Field::Option.new(*%w[person1 Person1])]
    di.options.size.must_equal 2
  end

  it 'can determine equality' do
    a = Blather::Stanza::X::Field.new('subject', 'text-single')
    a.must_equal Blather::Stanza::X::Field.new('subject', 'text-single')
    a.wont_equal Blather::Stanza::X::Field.new('subject1', 'text-single')
  end
end

describe Blather::Stanza::X::Field::Option do

  it 'has a value attribute' do
    n = Blather::Stanza::X::Field::Option.new 'person1', 'Person 1'
    n.value.must_equal 'person1'
    n.value = 'book1'
    n.value.must_equal 'book1'
  end

  it 'has a label attribute' do
    n = Blather::Stanza::X::Field::Option.new 'person1', 'Person 1'
    n.label.must_equal 'Person 1'
    n.label = 'Book 1'
    n.label.must_equal 'Book 1'
    n.label = 'Book 2'
    n.label.must_equal 'Book 2'
  end
end
