require 'spec_helper'

module ImageFactory
  describe ImageFactoryConsole do
    context "needs a real agent running" do
      # for now, these all require an actual agent on the bus
      before(:all) do
        @logger = Logger.new(STDOUT)
        @logger.level = Logger::DEBUG
        @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
        @i = ImageFactoryConsole.new() # Pass this in for more logging: (:logger => @logger)
        @i.start
        # Sadly, this is needed so we wait for an agent to appear.
        # We might be able to extract this somewhere to hold off
        # on tests until we get an agent_added notification
        sleep(5)
        #TODO: take this snippet and make a fixture of some sort to use in tests
        #tmpl = '<template> <name>tmpl1</name> <description>foo</description> <os> <name>Fedora</name>
        # <arch>x86_64</arch> <version>14</version> <install type="url">
        # <url>http://download.fedoraproject.org/pub/fedora/linux/releases/14/Fedora/x86_64/os/</url> </install>
        # </os> <repositories> <repository name="custom"> <url>http://repos.fedorapeople.org/repos/aeolus/demo/webapp/</url>
        # <signed>false</signed> </repository> </repositories> </template>'
      end

      describe "#q" do
        it "should get an agent set" do
          @i.q.should_not be_nil
        end
      end

      describe "#build_image" do
        it "should return a build-adaptor with uuid" do
          @i.build_image("<template></template>", "mock").image_id.should_not be_nil
        end
      end

      describe "#push_image" do
        it "should return a build-adaptor with uuid" do
          @image = @i.build_image("<template></template>", "mock")
          #@i.handler = BaseHandler.new(@logger)
          @i.handler.should_not_receive(:handle_failed)
          @i.push_image(@image.image_id, "mock", "some creds").image_id.should_not be_nil
        end
      end

      describe "#import_image" do
        it "should return a build-adaptor with uuid" do
          @import = @i.import_image("", "", "ami-test", "<image><name>Test Image</name></image>", "ec2", "ec2-us-east-1")
          is_uuid?(@import['image']).should == true
          is_uuid?(@import['target_image']).should == true
          is_uuid?(@import['build']).should == true
          is_uuid?(@import['provider_image']).should == true
        end
      end

      describe "#build" do
        it "should return an array of build-adaptors with uuids" do
          @i.build("<template></template>", ["mock"]).each do |adaptor|
            adaptor.image_id.should_not be_nil
            adaptor.image.should_not be_nil
            adaptor.build.should_not be_nil
          end
        end

        it "should work with single target as string" do
          @i.build("<template></template>", "mock").each do |adaptor|
            adaptor.image_id.should_not be_nil
            adaptor.image.should_not be_nil
            adaptor.build.should_not be_nil
          end
        end
      end

      describe "#push" do
        it "should return an array of build-adaptors with uuids" do
          @i.build("<template></template>", ["mock"]).each do |adaptor|
            #@i.handler = BaseHandler.new(@logger)
            @i.handler.should_not_receive(:handle_failed)
            @i.push(["mock"], "<provider_credentials/>", adaptor.image).each do |a|
              a.image_id.should_not be_nil
              a.image.should_not be_nil
              a.build.should_not be_nil
            end
          end
        end

        it "should work with single provider as string" do
          @i.build("<template></template>", "mock").each do |adaptor|
            #@i.handler = BaseHandler.new(@logger)
            @i.handler.should_not_receive(:handle_failed)
            @i.push("mock1", "<provider_credentials/>", adaptor.image).each do |a|
              a.image_id.should_not be_nil
              a.image.should_not be_nil
              a.build.should_not be_nil
            end
          end
        end
      end

      after(:all) do
        @i.shutdown
      end
    end

    context "agent is stubbed" do
      before(:each) do
         @agent = mock('agent', :null_object => true)
         @agent.stub(:product).and_return("imagefactory")
         @agent.stub(:name).and_return("redhat.com:imagefactory:b9e131c7-7905-409e-bfb5-dd4848a776a7")
         @output = double('output')
         @i2 = ImageFactoryConsole.new(:logger => @output)
      end

      describe "#agent_added" do
        it "logs when a new agent appears" do
          @output.should_receive(:debug).with(/GOT AN AGENT/).as_null_object
          @i2.agent_added(@agent)
        end

        it "stores a reference to that agent if it is a factory" do
          @output.should_receive(:debug).with(/GOT AN AGENT/)
          @i2.agent_added(@agent)
          @i2.q.should respond_to(:product)
        end
      end

      describe "#agent_deleted" do
        before(:each) do
          @old_agent = mock('agent', :null_object => true)
          @old_agent.stub(:product).and_return("imagefactory")
          @old_agent.stub(:name).and_return("redhat.com:imagefactory:4eb3776e-d91e-4239-9a73-3ab43ecc7e15")
          @output.should_receive(:debug).with(/GOT AN AGENT/)
          @i2.agent_added(@agent)
        end

        it "logs when an agent is removed" do
          @output.should_receive(:debug).with(/AGENT GONE/).as_null_object
          @i2.agent_deleted(@agent, "aged")
        end

        it "removes the agent reference if removed agent is the same as console reference" do
          @output.should_receive(:debug).with(/AGENT GONE/).as_null_object
          @i2.agent_deleted(@agent, "aged")
          @i2.q.should be_nil
        end

         it "does not remove the agent reference if removed agent is the not same as console reference" do
          @output.should_receive(:debug).with(/AGENT GONE/).as_null_object
          @i2.agent_deleted(@old_agent, "aged")
          @i2.q.should_not be_nil
        end
      end

      describe "#event_raised" do
        before(:each) do
          @data = mock('data', :null_object => true)
          @data.stub(:event).and_return("STATUS")
        end

        it "should call handle on an event" do
          @output.should_receive(:debug).with(/GOT AN EVENT/)

          @i2.handler.should_receive(:handle).once
          @i2.event_raised(@agent, @data, Time.now, "horrid")
        end
      end

      describe "#build_image" do
        it "should gracefully handle errors" do
          @output.should_receive(:debug).with(/Encountered error in build_image/)
          @output.should_receive(:warn).with("[DEPRECATION] 'build_image' is deprecated.  Please use 'build' instead.")
          @i2.q=nil
          error = @i2.build_image("<template></template>", "mock")
          error.to_s.should include("undefined method")
        end
      end

       describe "#push_image" do
        it "should gracefully handle errors" do
          @output.should_receive(:debug).with(/Encountered error in push_image/)
          @output.should_receive(:warn).with("[DEPRECATION] 'push_image' is deprecated.  Please use 'push' instead.")
          @i2.q=nil
          error = @i2.push_image(123, "mock", "some creds")
          error.to_s.should include("undefined method")
        end
      end

      describe "#build" do
        it "should gracefully handle errors" do
          @output.should_receive(:debug).with(/Encountered error in build_image/)
          @i2.q=nil
          error = @i2.build("<template></template>", "mock")
          error.to_s.should include("undefined method")
        end
      end

       describe "#push" do
        it "should gracefully handle errors" do
          @output.should_receive(:debug).with(/Encountered error in push_image/)
          @i2.q=nil
          error = @i2.push(123, "mock", "some creds")
          error.to_s.should include("undefined method")
        end
      end

      after(:each) do
         @output.should_receive(:debug).with(/Closing/)
         @i2.shutdown
      end
    end

    def is_uuid?(test_string)
      regexp = Regexp.new('^[\w]{8}[-][\w]{4}[-][\w]{4}[-][\w]{4}[-][\w]{12}')
      regexp.match(test_string) ? true : false
    end
  end
end
