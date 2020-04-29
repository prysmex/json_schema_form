require 'json_schema_form'

describe JsonSchemaForm::Type do
  it "broccoli is gross" do
    expect(JsonSchemaForm::Type.portray("Broccoli")).to eql("Gross!")
  end

  it "anything else is delicious" do
    expect(JsonSchemaForm::Type.portray("Not Broccoli")).to eql("Delicious!")
  end
end