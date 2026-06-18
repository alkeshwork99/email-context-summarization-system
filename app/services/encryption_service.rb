require "openssl"
require "base64"

class EncryptionService
  ALGORITHM  = "aes-256-gcm"
  IV_LENGTH  = 12
  TAG_LENGTH = 16

  class << self
    def encrypt(plaintext)
      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.encrypt
      cipher.key = encryption_key
      iv = cipher.random_iv
      cipher.auth_data = ""

      encrypted = cipher.update(plaintext.to_s) + cipher.final
      auth_tag  = cipher.auth_tag

      Base64.strict_encode64(iv + auth_tag + encrypted)
    end

    def decrypt(ciphertext)
      decoded   = Base64.strict_decode64(ciphertext)
      iv        = decoded[0, IV_LENGTH]
      auth_tag  = decoded[IV_LENGTH, TAG_LENGTH]
      encrypted = decoded[(IV_LENGTH + TAG_LENGTH)..]

      cipher = OpenSSL::Cipher.new(ALGORITHM)
      cipher.decrypt
      cipher.key       = encryption_key
      cipher.iv        = iv
      cipher.auth_tag  = auth_tag
      cipher.auth_data = ""

      (cipher.update(encrypted) + cipher.final).force_encoding(Encoding::UTF_8)
    end

    private

    def encryption_key
      [ ENV["ENCRYPTION_KEY"] ].pack("H*")
    end
  end
end
