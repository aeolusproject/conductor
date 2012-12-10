class ChangeTextInputTypeToStringInCredentalDefinitions < ActiveRecord::Migration
  def up
    CredentialDefinition.update_all("input_type = 'string'", "input_type = 'text'")
  end

  def down
    CredentialDefinition.update_all("input_type = 'text'", "input_type = 'string'")
  end
end
