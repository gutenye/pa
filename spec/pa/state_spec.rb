require "spec_helper"

describe Pa do
  it ".exists?" do
    File.should_receive(:exists?).with("foo")
    Pa.exists?("foo")
  end

  it "#exists?" do
    File.should_receive(:exists?).with("foo")
    Pa.new("foo").exists?
  end
end
