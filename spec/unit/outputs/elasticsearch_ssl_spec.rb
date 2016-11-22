require_relative "../../../spec/es_spec_helper"
require 'stud/temporary'
require "logstash/outputs/elasticsearch"

describe "SSL option" do
  context "when using ssl without cert verification" do
    subject do
      require "logstash/outputs/elasticsearch"
      settings = {
        "hosts" => "localhost",
        "ssl" => true,
        "ssl_certificate_verification" => false,
        "pool_max" => 1,
        "pool_max_per_route" => 1
      }
      next LogStash::Outputs::ElasticSearch.new(settings)
    end

    it "should pass the flag to the ES client" do
      expect(::Manticore::Client).to receive(:new).and_call_original do |args|
        expect(args[:ssl]).to eq(:enabled => true, :verify => false)
      end
      subject.register
    end

    it "should print a warning" do
      disabled_matcher = /You have enabled encryption but DISABLED certificate verification/
      expect(subject.logger).to receive(:warn).with(disabled_matcher).at_least(:once)
      allow(subject.logger).to receive(:warn).with(any_args)
      subject.register
    end
  end

  context "when using ssl with client certificates" do
    let(:keystore_path) { Stud::Temporary.file.path }
    before do
      `openssl req -x509  -batch -nodes -newkey rsa:2048 -keyout lumberjack.key -out #{keystore_path}.pem`
    end

    after :each do
      File.delete(keystore_path)
    end

    subject do
      require "logstash/outputs/elasticsearch"
      settings = {
        "hosts" => "node01",
        "ssl" => true,
        "cacert" => keystore_path,
      }
      next LogStash::Outputs::ElasticSearch.new(settings)
    end

    it "should pass the keystore parameters to the ES client" do
      expect(::Manticore::Client).to receive(:new) do |args|
        expect(args[:ssl]).to include(:keystore => keystore_path, :keystore_password => "test")
      end.and_call_original
      subject.register
    end

  end
end
