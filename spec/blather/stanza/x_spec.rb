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
    x.type.should == :form
    x.should be_instance_of Blather::Stanza::X
  end

  [:cancel, :form, :result, :submit].each do |type|
    it "type can be set as \"#{type}\"" do
      x = Blather::Stanza::X.new type
      x.type.should == type
    end
  end

  it 'is constructed properly' do
    n = Blather::Stanza::X.new :form
    n.xpath("/ns:x[@type='form']", :ns => Blather::Stanza::X.registered_ns).should_not be_empty
  end

  it 'has an action attribute' do
    n = Blather::Stanza::X.new :form
    n.type.should == :form
    n.type = :submit
    n.type.should == :submit
  end

  it 'has a title attribute' do
    n = Blather::Stanza::X.new :form
    n.title.should == nil
    n.title = "Hello World!"
    n.title.should == "Hello World!"
    n.title = "goodbye"
    n.title.should == "goodbye"
  end

  it 'has an instructions attribute' do
    n = Blather::Stanza::X.new :form
    n.instructions.should == nil
    n.instructions = "Please fill in this form"
    n.instructions.should == "Please fill in this form"
    n.instructions = "goodbye"
    n.instructions.should == "goodbye"
  end

  it 'inherits a list of fields' do
    n = Blather::Stanza::Iq::Command.new
    n.command << parse_stanza(x_xml).root
    r = Blather::Stanza::X.new.inherit n.form
    r.fields.size.should == 4
    r.fields.map { |f| f.class }.uniq.should == [Blather::Stanza::X::Field]
  end

  it 'returns a field object for a particular var' do
    x = Blather::Stanza::X.new parse_stanza(x_xml).root
    f = x.field 'field-name4'
    f.should be_instance_of Blather::Stanza::X::Field
    f.value.should == 'field-value4'
  end

  it 'takes a list of hashes for fields' do
    fields = [
      {:label => 'label', :type => 'text-single', :var => 'var'},
      {:label => 'label1', :type => 'text-single', :var => 'var1'},
    ]

    control = [ Blather::Stanza::X::Field.new(*%w[var text-single label]),
                Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]

    di = Blather::Stanza::X.new nil, fields
    di.fields.size.should == 2
    di.fields.each { |f| control.include?(f).should == true }
  end

  it 'takes a list of Field objects as fields' do
    control = [ Blather::Stanza::X::Field.new(*%w[var text-single label1]),
                Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]

    di = Blather::Stanza::X.new nil, control
    di.fields.size.should == 2
    di.fields.each { |f| control.include?(f).should == true }
  end

  it 'takes a mix of hashes and field objects as fields' do
    fields = [
      {:label => 'label', :type => 'text-single', :var => 'var'},
      Blather::Stanza::X::Field.new(*%w[var1 text-single label1]),
    ]

    control = [ Blather::Stanza::X::Field.new(*%w[var text-single label]),
                Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]

    di = Blather::Stanza::X.new nil, fields
    di.fields.size.should == 2
    di.fields.each { |f| control.include?(f).should == true }
  end

  it 'allows adding of fields' do
    di = Blather::Stanza::X.new nil
    di.fields.size.should == 0
    di.fields = [{:label => 'label', :type => 'text-single', :var => 'var', :required => true}]
    di.fields.size.should == 1
    di.fields += [Blather::Stanza::X::Field.new(*%w[var1 text-single label1])]
    di.fields.size.should == 2
  end

end

describe Blather::Stanza::X::Field do
  subject { Blather::Stanza::X::Field.new nil }

  it "should have the namespace 'jabber:x:data'" do
    subject.namespace.href.should be == 'jabber:x:data'
  end

  it 'will auto-inherit nodes' do
    n = parse_stanza "<field type='text-single' var='music' label='Music from the time of Shakespeare' />"
    i = Blather::Stanza::X::Field.new n.root
    i.type.should == 'text-single'
    i.var.should == 'music'
    i.label.should == 'Music from the time of Shakespeare'
  end

  it 'has a type attribute' do
    n = Blather::Stanza::X::Field.new 'var', 'text-single'
    n.type.should == 'text-single'
    n.type = 'hidden'
    n.type.should == 'hidden'
  end

  it 'has a var attribute' do
    n = Blather::Stanza::X::Field.new 'name', 'text-single'
    n.var.should == 'name'
    n.var = 'email'
    n.var.should == 'email'
  end

  it 'has a label attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    n.label.should == 'Music from the time of Shakespeare'
    n.label = 'Books by and about Shakespeare'
    n.label.should == 'Books by and about Shakespeare'
  end

  it 'has a desc attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    n.desc.should == nil
    n.desc = 'Books by and about Shakespeare'
    n.desc.should == 'Books by and about Shakespeare'
    n.desc = 'goodbye'
    n.desc.should == 'goodbye'
  end

  it 'has a required? attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    n.required?.should == false
    n.required = true
    n.required?.should == true
    n.required = false
    n.required?.should == false
  end

  it 'has a value attribute' do
    n = Blather::Stanza::X::Field.new 'subject', 'text-single', 'Music from the time of Shakespeare'
    n.value.should == nil
    n.value = 'book1'
    n.value.should == 'book1'
    n.value = 'book2'
    n.value.should == 'book2'
  end

  it 'allows setting options' do
    di = Blather::Stanza::X::Field.new nil
    di.options.size.should == 0
    di.options = [{:label => 'Person', :value => 'person'}, Blather::Stanza::X::Field::Option.new(*%w[person1 Person1])]
    di.options.size.should == 2
  end

  it 'can determine equality' do
    a = Blather::Stanza::X::Field.new('subject', 'text-single')
    a.should == Blather::Stanza::X::Field.new('subject', 'text-single')
    a.should_not equal Blather::Stanza::X::Field.new('subject1', 'text-single')
  end
end

describe Blather::Stanza::X::Field::Option do

  it 'has a value attribute' do
    n = Blather::Stanza::X::Field::Option.new 'person1', 'Person 1'
    n.value.should == 'person1'
    n.value = 'book1'
    n.value.should == 'book1'
  end

  it 'has a label attribute' do
    n = Blather::Stanza::X::Field::Option.new 'person1', 'Person 1'
    n.label.should == 'Person 1'
    n.label = 'Book 1'
    n.label.should == 'Book 1'
    n.label = 'Book 2'
    n.label.should == 'Book 2'
  end
end
