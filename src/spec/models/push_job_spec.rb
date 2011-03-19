require 'spec_helper'

describe PushJob do
  it "should match request and parse stubbed xml" do
    image_id="6669978e-97a3-4381-92cb-2fbc160b49c7"
    response = RestClient::Response.create("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<image>\n  <uuid>#{image_id}</uuid>\n</image>\n", 200, {})
    response.stub(:code).and_return(200)
    RestClient.stub(:post).and_return(response)
    job = Factory.build(:push_job)
    uuid = job.perform
    uuid.should == image_id
  end
end
