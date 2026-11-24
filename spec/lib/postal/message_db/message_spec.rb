# frozen_string_literal: true

require "rails_helper"

describe Postal::MessageDB::Message do
  describe "#inspect_message" do
    let(:server) { create(:server) }
    let(:message) { MessageFactory.incoming(server) }

    it "stores only the first 250 characters of a spam check description" do
      short_check = Postal::SpamCheck.new("SHORT", 0, "Short description")
      long_check = Postal::SpamCheck.new("LONG", 0, "é" * 240)
      long_check.description << ("界" * 20)
      inspection = Postal::MessageInspection.new(message, :incoming)
      inspection.spam_checks.push(short_check, long_check)
      allow(Postal::MessageInspection).to receive(:scan).with(message, :incoming).and_return(inspection)

      message.inspect_message

      descriptions = message.spam_checks.to_h { |check| [check["code"], check["description"]] }
      expect(descriptions).to eq("SHORT" => "Short description", "LONG" => ("é" * 240) + ("界" * 10))
    end

    it "decodes a binary spam check description before applying the character limit" do
      prefix = "a" + ("é" * 249)
      check = Postal::SpamCheck.new("BINARY", 0, prefix.b)
      check.description << "界".b
      inspection = Postal::MessageInspection.new(message, :incoming)
      inspection.spam_checks << check
      allow(Postal::MessageInspection).to receive(:scan).with(message, :incoming).and_return(inspection)

      message.inspect_message

      expect(message.spam_checks.first.fetch("description")).to eq(prefix)
    end
  end
end
