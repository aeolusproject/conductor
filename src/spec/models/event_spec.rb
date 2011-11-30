# #
# # Copyright (C) 2011 Red Hat, Inc.
# #
# # This program is free software; you can redistribute it and/or modify
# # it under the terms of the GNU General Public License as published by
# # the Free Software Foundation; version 2 of the License.
# #
# # This program is distributed in the hope that it will be useful,
# # but WITHOUT ANY WARRANTY; without even the implied warranty of
# # MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# # GNU General Public License for more details.
# #
# # You should have received a copy of the GNU General Public License
# # along with this program; if not, write to the Free Software
# # Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# # MA  02110-1301, USA.  A copy of the GNU General Public License is
# # also available at http://www.gnu.org/copyleft/gpl.html.

# require 'spec_helper'

# describe Event do

#   it "should create a CIDR for started Instances" do
#     deployment = Factory.create(:deployment)
#     instance = Factory.create(:mock_pending_instance, :deployment => deployment)
#     Aeolus::Event::Cidr.should_receive(:new).with(
#       hash_including(
#         :instance_id => instance.id,
#         :deployment_id => deployment.id,
#         :terminate_time => nil,
#         :action => Instance::STATE_RUNNING
#       )
#     )
#     instance.state = Instance::STATE_RUNNING
#     instance.save!
#   end

#   it "should create and process a CIDR for stopped Instances" do
#     deployment = Factory.create(:deployment)
#     instance = Factory.create(:mock_pending_instance, :deployment => deployment)
#     Aeolus::Event::Cidr.should_receive(:new).with(
#       hash_including(
#         :instance_id => instance.id,
#         :deployment_id => deployment.id,
#         :action => Instance::STATE_STOPPED
#       )
#     )
#     # If the instance doesn't move from pending -> running, we don't get an event, so
#     # we have to go pending -> running -> stopped here
#     instance.state = Instance::STATE_RUNNING
#     instance.save!
#     instance.state = Instance::STATE_STOPPED
#     changes = instance.changes
#     instance.save!
#   end

#   it "should create and process a CDDR for starting Deployments" do
#     deployment = Factory.create(:deployment)
#     Aeolus::Event::Cddr.should_receive(:new).with(
#       hash_including(
#         :deployment_id => deployment.id,
#         :action => 'first_running'
#       )
#     )
#     instance1 = Factory.create(:mock_pending_instance, :deployment => deployment)
#     # We deliberately don't use instance2 here -- we never get to all_running
#     instance2 = Factory.create(:mock_pending_instance, :deployment => deployment)
#     instance1.state = Instance::STATE_RUNNING
#     instance1.save!
#   end

#   it "should create and process a CDDR for started Deployments" do
#     deployment = Factory.create(:deployment)
#     Aeolus::Event::Cddr.should_receive(:new).with(
#       hash_including(
#         :deployment_id => deployment.id,
#         :action => 'all_running'
#       )
#     )
#     instance1 = Factory.create(:mock_pending_instance, :deployment => deployment)
#     instance2 = Factory.create(:mock_pending_instance, :deployment => deployment)
#     instance1.state = Instance::STATE_RUNNING
#     instance2.state = Instance::STATE_RUNNING
#     instance1.save!
#     instance2.save!
#   end

#   it "should create and process a CDDR for stopping Deployments" do
#     deployment = Factory.create(:deployment)
#     Aeolus::Event::Cddr.should_receive(:new).with(
#       hash_including(
#         :deployment_id => deployment.id,
#         :action => 'some_stopped'
#       )
#     )
#     instance1 = Factory.create(:mock_pending_instance, :deployment => deployment)
#     instance2 = Factory.create(:mock_pending_instance, :deployment => deployment)
#     instance1.state = Instance::STATE_RUNNING
#     instance2.state = Instance::STATE_RUNNING
#     instance1.save!
#     instance2.save!
#     instance1.state = Instance::STATE_STOPPED
#     instance1.save!
#   end

#   it "should create and process a CDDR for stopping Deployments" do
#     deployment = Factory.create(:deployment)
#     Aeolus::Event::Cddr.should_receive(:new).with(
#       hash_including(
#         :deployment_id => deployment.id,
#         :action => 'all_stopped'
#       )
#     )
#     instance1 = Factory.create(:mock_pending_instance, :deployment => deployment)
#     instance2 = Factory.create(:mock_pending_instance, :deployment => deployment)
#     [Instance::STATE_RUNNING, Instance::STATE_STOPPED].each do |state|
#       [instance1, instance2].each do |instance|
#         instance.state = state
#         instance.save!
#       end
#     end
#   end


# end
