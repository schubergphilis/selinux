require_relative '../../libraries/selinux_rules'


describe SELinux::Rule do
  before :all do
    SELinux::Rule.new("name", "source target:class permission", "comment") 
  end

  it "should contain one rule in the instance rules" do
    expect(SELinux.instance.rules.count).to eql(1)
  end

  it "should contain two types in the instance types" do
    expect(SELinux.instance.types.count).to eql(2)
  end

  it "should contain one class in the instance classes" do
    expect(SELinux.instance.classes.count).to eql(1)
  end

  it "should detect wrong input" do
    SELinux::Rule.new("name", "just-some-wrong-information", "comment")
    expect(SELinux.instance.classes.count).to eql(1)
  end
end
