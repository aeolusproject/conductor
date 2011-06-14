require 'spec_helper'

module Aeolus
  module Image
    describe BaseCommand do
      describe BaseCommand do
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
      end
    end
  end
end