require "spec_helper"

describe Pa do
	describe "#<=>" do
		it "runs ok" do
			(Pa('/home/b') <=> Pa('/home/a')).should == 1
		end
	end
end
