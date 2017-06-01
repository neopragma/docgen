require "spec_helper"

describe 'Structural attributes' do

  it "has a version number" do
    expect(Docgen::VERSION).not_to be nil
  end

end
