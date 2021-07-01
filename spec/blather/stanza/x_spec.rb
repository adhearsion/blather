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
    expect(x.type).to eq(:form)
    expect(x).to be_instance_of Blather::Stanza::X
  end

  [:cancel, :form, :result, :submit].each do |type|
    it "type can be set as \"#{type}\"" do
      x = Blather::Stanza::X.new type
      expect(x.type).to eq(type)
    end
  end

  it 'is constructed properly' do
    n = Blather::Stanza::X.new :form
    expect(n.find("/ns:x[@type='form']", :ns => Blather::Stanza::X.registered_ns)).not_to be_empty
  end

  it 'has an action attribute' do
    n = Blather::Stanza::X.new :form
    expect(n.type).to eq(:form)
    n.type = :submit
    expect(n.type).to eq(:submit)
  end

  it 'has a title attribute' do
    n = Blather::Stanza::X.new :form
    expect(n.title).to eq(nil)
    n.title = "Hello World!"
    expect(n.title).to eq("Hello World!")
    n.title = "goodbye"
    expect(n.title).to eq("goodbye")
  end

  it 'has an instructions attribute' do
    n = Blather::Stanza::X.new :form
    expect(n.instructions).to eq(nil)
    n.instructions = "Please fill in this form"
    expect(n.instructions).to eq("Please fill in this form")
    n.instructions = "goodbye"
    expect(n.instructions).to eq("goodbye")
  end

  it 'inherits a list of fields' do
    n = Blather::Stanza::Iq::Command.new
    n.command << parse_stanza(x_xml).root
    r = Blather::Stanza::X.new.inherit n.form
    expect(r.fields.size).to eq(4)
    expect(r.fields.map { |f| f.class }.uniq).to eq([Blather::Stanza::X::Field])
  end

  it 'returns a field object for a particular var' do
    x = Blather::Stanza::X.new parse_stanza(x_xml).root
    f = x.field 'field-name4'
    expect(f).to be_instance_of Blather::Stanza::X::Field
    expect(f.value).to eq('field-value4')
  end

  it 'takes a list of hashes for fields' do
    fields = [
      {:label => 'label', :type => 'text-single', :var => 'var'},
      {:label => 'label1', :type => 'text-single', :var => 'var1'},
    ]

    control = [ Blather::Stanza::X::Field.new(*%w[var text-single label]),
                Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]

    di = Blather::Stanza::X.new nil, fields
    expect(di.fields.size).to eq(2)
    di.fields.each { |f| expect(control.include?(f)).to eq(true) }
  end

  it 'takes a list of Field objects as fields' do
    control = [ Blather::Stanza::X::Field.new(*%w[var text-single label1]),
                Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]

    di = Blather::Stanza::X.new nil, control
    expect(di.fields.size).to eq(2)
    di.fields.each { |f| expect(control.include?(f)).to eq(true) }
  end

  it 'takes a mix of hashes and field objects as fields' do
    fields = [
      {:label => 'label', :type => 'text-single', :var => 'var'},
      Blather::Stanza::X::Field.new(*%w[var1 text-single label1]),
    ]

    control = [ Blather::Stanza::X::Field.new(*%w[var text-single label]),
                Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]

    di = Blather::Stanza::X.new nil, fields
    expect(di.fields.size).to eq(2)
    di.fields.each { |f| expect(control.include?(f)).to eq(true) }
  end

  it 'allows adding of fields' do
    di = Blather::Stanza::X.new nil
    expect(di.fields.size).to eq(0)
    di.fields = [{:label => 'label', :type => 'text-single', :var => 'var', :required => true}]
    expect(di.fields.size).to eq(1)
    di.fields += [Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]
    expect(di.fields.size).to eq(2)
  end

end

describe Blather::Stanza::X::Field do
  subject { Blather::Stanza::X::Field.new nil }

  it "should have the namespace 'jabber:x:data'" do
    expect(subject.namespace.href).to eq('jabber:x:data')
  end

  it 'will auto-inherit nodes' do
    n = parse_stanza "<field type='text-single' var='music' label='Music from the time of Shakespeare' />"
    i = Blather::Stanza::X::Field.new n.root
    expect(i.type).to eq('text-single')
    expect(i.var).to eq('music')
    expect(i.label).to eq('Music from the time of Shakespeare')
  end

  it 'has a type attribute' do
    n = Blather::Stanza::X::Field.new 'var', 'text-single'
    expect(n.type).to eq('text-single')
    n.type = 'hidden'
    expect(n.type).to eq('hidden')
  end

  it 'has a var attribute' do
    n = Blather::Stanza::X::Field.new 'name', 'text-single'
    expect(n.var).to eq('name')
    n.var = 'email'
    expect(n.var).to eq('email')
  end

  it 'has a label attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    expect(n.label).to eq('Music from the time of Shakespeare')
    n.label = 'Books by and about Shakespeare'
    expect(n.label).to eq('Books by and about Shakespeare')
  end

  it 'has a desc attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    expect(n.desc).to eq(nil)
    n.desc = 'Books by and about Shakespeare'
    expect(n.desc).to eq('Books by and about Shakespeare')
    n.desc = 'goodbye'
    expect(n.desc).to eq('goodbye')
  end

  it 'has a required? attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    expect(n.required?).to eq(false)
    n.required = true
    expect(n.required?).to eq(true)
    n.required = false
    expect(n.required?).to eq(false)
  end

  it 'has a value attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    expect(n.value).to eq(nil)
    n.value = 'book1'
    expect(n.value).to eq('book1')
    n.value = 'book2'
    expect(n.value).to eq('book2')
  end

  it 'allows multiple values' do
    n = Blather::Stanza::X::Field.new 'subject', 'list-multi', 'Music from the time of Shakespeare'
    expect(n.value).to eq(nil)
    n.value = ['book<&1>', 'book2']
    expect(n.value).to eq(['book<&1>', 'book2'])
  end

  it 'allows setting options' do
    di = Blather::Stanza::X::Field.new nil
    expect(di.options.size).to eq(0)
    di.options = [{:label => 'Person', :value => 'person'}, Blather::Stanza::X::Field::Option.new(*%w[person1 Person1])]
    expect(di.options.size).to eq(2)
  end

  it 'can determine equality' do
    a = Blather::Stanza::X::Field.new('subject', 'text-single')
    expect(a).to eq(Blather::Stanza::X::Field.new('subject', 'text-single'))
    expect(a).not_to equal Blather::Stanza::X::Field.new('subject1', 'text-single')
  end
end

describe Blather::Stanza::X::Field::Option do

  it 'has a value attribute' do
    n = Blather::Stanza::X::Field::Option.new 'person1', 'Person 1'
    expect(n.value).to eq('person1')
    n.value = 'book1'
    expect(n.value).to eq('book1')
  end

  it 'has a label attribute' do
    n = Blather::Stanza::X::Field::Option.new 'person1', 'Person 1'
    expect(n.label).to eq('Person 1')
    n.label = 'Book 1'
    expect(n.label).to eq('Book 1')
    n.label = 'Book 2'
    expect(n.label).to eq('Book 2')
  end
end
