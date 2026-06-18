require "rails_helper"

describe EncryptionService do
  let(:plaintext) { "Hello, World!" }

  describe ".encrypt / .decrypt" do
    it "round-trips plaintext" do
      ciphertext = EncryptionService.encrypt(plaintext)
      expect(EncryptionService.decrypt(ciphertext)).to eq(plaintext)
    end

    it "produces different ciphertexts for the same plaintext" do
      expect(EncryptionService.encrypt(plaintext)).not_to eq(EncryptionService.encrypt(plaintext))
    end

    it "handles Unicode correctly" do
      unicode = "Résumé नमस्ते"
      expect(EncryptionService.decrypt(EncryptionService.encrypt(unicode))).to eq(unicode)
    end
  end

  describe ".decrypt" do
    it "raises OpenSSL::Cipher::CipherError for a tampered ciphertext" do
      ciphertext = EncryptionService.encrypt(plaintext)
      raw = Base64.strict_decode64(ciphertext)
      raw.setbyte(20, raw.getbyte(20) ^ 0xFF)
      tampered = Base64.strict_encode64(raw)
      expect { EncryptionService.decrypt(tampered) }.to raise_error(OpenSSL::Cipher::CipherError)
    end
  end
end
