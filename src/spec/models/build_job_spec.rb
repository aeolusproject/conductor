require 'spec_helper'

describe BuildJob do
  it "should match request and parse stubbed xml" do
    job = Factory.build(:build_job)
    uuid = job.perform
    uuid.should == "build-job-stub-uuid"
  end
end
