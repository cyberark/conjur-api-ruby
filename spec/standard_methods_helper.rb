shared_examples_for 'standard_create with' do |type, id, options|
  it "calls through to standard_create" do
    subject.should_receive(:standard_create).with(
      core_host, type, id, options
    ).and_return :response
    invoke.should == :response
  end
end

shared_examples_for 'standard_list with' do |type, options|
  it "calls through to standard_create" do
    subject.should_receive(:standard_list).with(
      core_host, type, options
    ).and_return :response
    invoke.should == :response
  end
end

shared_examples_for 'standard_show with' do |type, id|
  it "calls through to standard_create" do
    subject.should_receive(:standard_show).with(
      core_host, type, id
    ).and_return :response
    invoke.should == :response
  end
end
