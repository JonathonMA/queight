require "spec_helper"

RSpec.describe "Queight::RabbitMQConfig" do
  it "uses the path as the vhost" do
    url = "amqp://guest:guest@localhost/%2Fexpected_vhost?size=10"

    config = Queight::RabbitMQConfig.new(url).config
    result = config[:vhost]

    expect(result).to eq "/expected_vhost"
  end

  it "uses a default vhost when path is absent" do
    url = "amqp://guest:guest@localhost?size=10"

    config = Queight::RabbitMQConfig.new(url).config
    result = config[:vhost]

    expect(result).to eq "/"
  end
end
