require "spec_helper"

Util = Pa::Util

describe Util do
  describe ".join" do
    it %~join(".", "foo") to "foo", not "./foo"~ do
      Util.join(".", "a", "b").should == "a/b"
      Util.join("a", "b", "c").should == "a/b/c"
    end
  end
end

