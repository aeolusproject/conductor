class UpdateCredentialDefinitionLabels < ActiveRecord::Migration
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
      "Access Key" => "access_key",
      "Secret Access Key" => "secret_access_key",
      "Account Number" => "account_number",
      "Username" => "username",
      "Key" => "key",
      "Certificate" => "certificate",
      "Password" => "password"
    }
  end
end
