require 'spec_helper'

describe PushJob do
  it "should match request and parse stubbed xml" do
    job = Factory.build(:push_job)
    uuid = job.perform
    uuid.should == "push-job-stub-uuid"
  end
end
