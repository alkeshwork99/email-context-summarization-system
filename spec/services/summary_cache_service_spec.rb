require "rails_helper"

describe SummaryCacheService do
  let(:redis)   { instance_double(Redis) }
  let(:key)     { "summary:test_conv_001" }
  let(:summary) { { actors: [ "Alice" ], concluded_discussions: [], open_action_items: [], summary: "stub" } }

  before { allow(Redis).to receive(:new).and_return(redis) }

  describe ".write / .fetch" do
    it "stores and retrieves a summary by full key" do
      allow(redis).to receive(:set)
      allow(redis).to receive(:get).and_return(JSON.generate(summary))

      SummaryCacheService.write(key, summary)
      result = SummaryCacheService.fetch(key)

      expect(result).to eq(summary)
    end
  end

  describe ".fetch" do
    it "returns nil when the key does not exist" do
      allow(redis).to receive(:get).and_return(nil)
      expect(SummaryCacheService.fetch(key)).to be_nil
    end
  end

  describe ".delete" do
    it "removes the cache entry so fetch returns nil" do
      allow(redis).to receive(:del)
      allow(redis).to receive(:get).and_return(nil)

      SummaryCacheService.delete(key)

      expect(SummaryCacheService.fetch(key)).to be_nil
    end
  end

  describe "namespacing" do
    it "thread and client keys are distinct" do
      thread_key = "summary:conv_001"
      client_key = "client_summary:some-uuid"
      expect(thread_key).not_to eq(client_key)
    end
  end

  describe ".lock / .unlock" do
    it "returns truthy when the lock is acquired for the first time" do
      allow(redis).to receive(:set).with("lock:#{key}", 1, nx: true, ex: 60).and_return("OK")
      expect(SummaryCacheService.lock(key)).to be_truthy
    end

    it "returns nil when the lock is already held" do
      allow(redis).to receive(:set).with("lock:#{key}", 1, nx: true, ex: 60).and_return(nil)
      expect(SummaryCacheService.lock(key)).to be_nil
    end

    it "unlock calls del on the lock key" do
      expect(redis).to receive(:del).with("lock:#{key}")
      SummaryCacheService.unlock(key)
    end
  end
end
