require 'spec_helper'

module Aeolus
  module Image
    describe BaseCommand do
      before(:each) do
        @stdout_orig = $stdout
        $stdout = StringIO.new
      end

      it "should determine the correct credentials for HTTP Authentication" do
        basec = BaseCommand.new
        iwhd = basec.send :iwhd
        iwhd.user.should == nil

        conductor = basec.send :conductor
        conductor.user.should == "admin"
        conductor.password.should == "password"

        basec = BaseCommand.new({'username' => "testusername", 'password'=> "testpassword"})
        conductor = basec.send :conductor
        conductor.user.should == "testusername"
        conductor.password.should == "testpassword"
      end

      describe "#read_file" do
        after(:each) do
          #@b.console.shutdown
        end

        it "should return nil when it cannot find file" do
          b = BaseCommand.new
          b.send(:read_file, "foo.fake").should == nil
        end

        it "should read file content into string variable" do
          b = BaseCommand.new
          template_str = b.send(:read_file, 'spec/sample_data/custom_repo.tdl')
          template_str.should include("<template>")
        end
      end
    end
  end
end