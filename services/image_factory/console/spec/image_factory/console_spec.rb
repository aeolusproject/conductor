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
          @i2.q=nil
          error = @i2.build_image("<template></template>", "mock")
          error.to_s.should include("undefined method")
        end
      end

       describe "#push_image" do
        it "should gracefully handle errors" do
          @output.should_receive(:debug).with(/Encountered error in push_image/)
          @i2.q=nil
          error = @i2.push_image(123, "mock", "some creds")
          error.to_s.should include("undefined method")
        end
      end

      after(:each) do
         @output.should_receive(:debug).with(/Closing/)
         @i2.shutdown
      end
    end

  end
end
