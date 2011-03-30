class ChangeCredentialDefinitionsNames < ActiveRecord::Migration
  def self.up
    CredentialDefinition.all.each do |cred|
      if name_mapping.has_key? cred.label
        cred.label = name_mapping[cred.label]
        cred.save!
      end
    end
  end

  def self.down
    reverse_mapping = name_mapping.invert
    CredentialDefinition.all.each do |cred|
      if reverse_mapping.has_key? cred.label
        cred.label = reverse_mapping[cred.label]
        cred.save!
      end
    end
  end

  def self.name_mapping
    {
      "API Key" => "Access Key",
      "Secret" => "Secret Access Key",
      "AWS Account ID" => "Account Number",
      "EC2 x509 private key" => "Key",
      "EC2 x509 public key" => "Certificate",
    }
  end
end
