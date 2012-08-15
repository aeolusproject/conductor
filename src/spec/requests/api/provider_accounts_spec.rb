require 'spec_helper'

describe "ProviderAccounts" do
  let(:headers) { {
    'HTTP_ACCEPT' => 'application/xml',
    'CONTENT_TYPE' => 'application/xml'
  } }
  before(:each) do
    user = FactoryGirl.create(:admin_permission).user
    login_as(user)
  end

  #  describe "GET /api/provider_accounts" do
  #    before(:each) do
  #      resp = get '/api/provider_accounts', nil, headers
  #    end
  #
  #    it_behaves_like "http OK"
  #    it_behaves_like "responding with XML"
  #  end

  describe "POST /api/providers/:provider_id/provider_accounts" do
    before(:each) do
      post "/api/providers/#{provider.id}/provider_accounts", xml, headers
    end

    context "with valid" do
      context "mock provider account XML" do
        let(:xml) do
          "<provider_account><label>mockaccount</label><credentials><username>mockuser</username><password>mockpassword</password></credentials></provider_account>"
        end
        let(:provider) { FactoryGirl.create(:mock_provider) }

        it_behaves_like "http OK"
        it_behaves_like "responding with XML"
        context "XML body" do
          subject { Nokogiri::XML(response.body) }
          it "should have correct nodes" do
            subject.xpath('//provider_account').size.should be_eql(1)
            subject.xpath('//provider_account/label').size.should be_eql(1)
            subject.xpath('//provider_account/label').text.should be_eql("mockaccount")
            subject.xpath('//provider_account/credentials').size.should be_eql(1)
            subject.xpath('//provider_account/credentials/username').size.should be_eql(1)
            subject.xpath('//provider_account/credentials/username').text.should be_eql("mockuser")
            subject.xpath('//provider_account/credentials/password').size.should be_eql(1)
            subject.xpath('//provider_account/credentials/password').text.should be_eql("mockpassword")
          end
        end
      end

      context "ec2 provider account XML" do
        let(:xml) do
          DeltaCloud.stub(:valid_credentials?).and_return(true)
          "<provider_account>
            <label>ec2account</label>
            <credentials>
              <username>ec2user</username>
              <password>ec2password</password>
              <account_id>ec2account_id</account_id>
              <x509private><![CDATA[ec2x509private]]></x509private>
              <x509public><![CDATA[ec2x509public]]></x509public>
            </credentials>
          </provider_account>"
        end
        let(:provider) { DeltaCloud.stub(:valid_credentials?).and_return(true); FactoryGirl.create(:ec2_provider) }

        it_behaves_like "http OK"
        it_behaves_like "responding with XML"
        context "XML body" do
          subject { Nokogiri::XML(response.body) }
          it "should have correct nodes" do
            subject.xpath('//provider_account').size.should be_eql(1)
            subject.xpath('//provider_account/label').size.should be_eql(1)
            subject.xpath('//provider_account/label').text.should be_eql("ec2account")
            subject.xpath('//provider_account/credentials').size.should be_eql(1)
            subject.xpath('//provider_account/credentials/username').size.should be_eql(1)
            subject.xpath('//provider_account/credentials/username').text.should be_eql("ec2user")
            subject.xpath('//provider_account/credentials/password').size.should be_eql(1)
            subject.xpath('//provider_account/credentials/password').text.should be_eql("ec2password")
            subject.xpath('//provider_account/credentials/x509private').size.should be_eql(1)
            subject.xpath('//provider_account/credentials/x509private').text.should be_eql("ec2x509private")
          end
        end
      end
    end

    context "with invalid" do
      context "mock provider account XML" do
        # omit label
        let(:xml) do
          "<provider_account><label></label><credentials><username>mockuser</username><password>mockpassword</password></credentials></provider_account>"
        end
        let(:provider) { FactoryGirl.create(:mock_provider) }

        it_behaves_like "http Bad Request"
        it_behaves_like "responding with XML"
        context "XML body" do
          subject { Nokogiri::XML(response.body) }
          it "should have some errors" do
            subject.xpath('//errors').size.should be_eql(1)
            subject.xpath('//errors/error').size.should <= 1
          end
        end

      end

      context "ec2 provider account XML" do
        # omit label
        let(:xml) do
          DeltaCloud.stub(:valid_credentials?).and_return(true)
          "<provider_account>
          <credentials>
            <username>ec2user</username>
            <password>ec2password</password>
            <account_id>ec2account_id</account_id>
            <x509private><![CDATA[ec2x509private]]></x509private>
            <x509public><![CDATA[ec2x509public]]></x509public>
          </credentials>
        </provider_account>"
        end
        let(:provider) { FactoryGirl.create(:ec2_provider) }

        it_behaves_like "http Bad Request"
        it_behaves_like "responding with XML"
        context "XML body" do
          subject { Nokogiri::XML(response.body) }
          it "should have some errors" do
            subject.xpath('//errors').size.should be_eql(1)
            subject.xpath('//errors/error').size.should <= 1
          end
        end
      end
    end
  end

  describe "PUT /api/provider_accounts/:provider_account_id" do
    before(:each) do
      put "/api/provider_accounts/#{provider_account.id}", xml, headers
    end

    context "for existing Provider Account" do
      context "with valid" do
        context "mock provider account XML" do
          let(:xml) do
            "<provider_account><label>mockaccount</label><credentials><username>mockuser</username><password>mockpassword</password></credentials></provider_account>"
          end
          let(:provider) { FactoryGirl.create(:mock_provider) }
          let(:provider_account) { FactoryGirl.create(:mock_provider_account, :provider => provider) }

          it_behaves_like "http OK"
          it_behaves_like "responding with XML"
          context "XML body" do
            subject { Nokogiri::XML(response.body) }
            it "should have correct nodes" do
              subject.xpath('//provider_account').size.should be_eql(1)
              subject.xpath('//provider_account/label').size.should be_eql(1)
              subject.xpath('//provider_account/label').text.should be_eql("mockaccount")
              subject.xpath('//provider_account/credentials').size.should be_eql(1)
              subject.xpath('//provider_account/credentials/username').size.should be_eql(1)
              subject.xpath('//provider_account/credentials/username').text.should be_eql("mockuser")
              subject.xpath('//provider_account/credentials/password').size.should be_eql(1)
              subject.xpath('//provider_account/credentials/password').text.should be_eql("mockpassword")
            end
          end
        end

        context "ec2 provider account XML" do
          let(:xml) do
            DeltaCloud.stub(:valid_credentials?).and_return(true)
            "<provider_account>
                         <label>ec2account</label>
                         <credentials>
                           <username>ec2user</username>
                           <password>ec2password</password>
                           <account_id>ec2account_id</account_id>
                           <x509private><![CDATA[ec2x509private]]></x509private>
                           <x509public><![CDATA[ec2x509public]]></x509public>
                         </credentials>
                       </provider_account>"
          end
          let(:provider) { FactoryGirl.create(:ec2_provider) }
          let(:provider_account) { DeltaCloud.stub(:valid_credentials?).and_return(true); FactoryGirl.create(:ec2_provider_account, :provider => provider) }

          it_behaves_like "http OK"
          it_behaves_like "responding with XML"
          context "XML body" do
            subject { Nokogiri::XML(response.body) }
            it "should have correct nodes" do
              subject.xpath('//provider_account').size.should be_eql(1)
              subject.xpath('//provider_account/label').size.should be_eql(1)
              subject.xpath('//provider_account/label').text.should be_eql("ec2account")
              subject.xpath('//provider_account/credentials').size.should be_eql(1)
              subject.xpath('//provider_account/credentials/username').size.should be_eql(1)
              subject.xpath('//provider_account/credentials/username').text.should be_eql("ec2user")
              subject.xpath('//provider_account/credentials/account_id').size.should be_eql(1)
              subject.xpath('//provider_account/credentials/account_id').text.should be_eql("ec2account_id")
              subject.xpath('//provider_account/credentials/password').size.should be_eql(1)
              subject.xpath('//provider_account/credentials/password').text.should be_eql("ec2password")
              subject.xpath('//provider_account/credentials/x509private').size.should be_eql(1)
              subject.xpath('//provider_account/credentials/x509private').text.should be_eql("ec2x509private")
              subject.xpath('//provider_account/credentials/x509public').size.should be_eql(1)
              subject.xpath('//provider_account/credentials/x509public').text.should be_eql("ec2x509public")
            end
          end
        end
      end

      context "with invalid" do
        context "mock provider account XML" do
          # omit label
          let(:xml) do
            "<provider_account><label></label><credentials><username>mockuser</username><password>mockpassword</password></credentials></provider_account>"
          end
          let(:provider) { FactoryGirl.create(:mock_provider) }
          let(:provider_account) { FactoryGirl.create(:mock_provider_account, :provider => provider) }

          it_behaves_like "http Bad Request"
          it_behaves_like "responding with XML"
          context "XML body" do
            subject { Nokogiri::XML(response.body) }
            it "should have some errors" do
              subject.xpath('//errors').size.should be_eql(1)
              subject.xpath('//errors/error').size.should <= 1
            end
          end

        end

        context "ec2 provider account XML" do
          # omit label
          let(:xml) do
            DeltaCloud.stub(:valid_credentials?).and_return(true)
            "<provider_account>
                         <label></label>
                         <credentials>
                           <username>ec2user</username>
                           <password>ec2password</password>
                           <account_id>ec2account_id</account_id>
                           <x509private><![CDATA[ec2x509private]]></x509private>
                           <x509public><![CDATA[ec2x509public]]></x509public>
                         </credentials>
                       </provider_account>"
          end
          let(:provider) { FactoryGirl.create(:ec2_provider) }
          let(:provider_account) { DeltaCloud.stub(:valid_credentials?).and_return(true); FactoryGirl.create(:ec2_provider_account, :provider => provider) }

          it_behaves_like "http Bad Request"
          it_behaves_like "responding with XML"
          context "XML body" do
            subject { Nokogiri::XML(response.body) }
            it "should have some errors" do
              subject.xpath('//errors').size.should be_eql(1)
              subject.xpath('//errors/error').size.should <= 1
            end
          end
        end
      end
    end

    context "for non existing Provider Account" do

      let(:provider_account) { provider_account = FactoryGirl.create(:mock_provider_account); ProviderAccount.delete(provider_account.id); provider_account }
      let(:xml) { "" }

      it_behaves_like "http Not Found"
      it_behaves_like "responding with XML"

      context "XML body" do
        subject { Nokogiri::XML(response.body) }

        it "have RecordNotFound error message" do
          subject.xpath('//error').size.should be_eql(1)
          subject.xpath('//error/code').text.should be_eql('RecordNotFound')
        end
      end

    end
  end
end
