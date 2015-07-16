require_relative 'xml_resp'
# http://mp.weixin.qq.com/wiki/2/3478f69c0d0bbe8deb48d66a3111ff6e.html

class Pkcs7
  BLK_SIZE = 32
  def encode(text)
    pad_size = BLK_SIZE - (text.size % BLK_SIZE)
    pad_size = BLK_SIZE if pad_size == 0
    text + pad_size.chr*pad_size
  end

  def decode(text)
    pad_size = text.last.ord
    pad_size = 0 if pad_size<0 || pad_size>BLK_SIZE
    text.first(text.size - pad_size)
  end
end

class Encrypt
  def initialize(token, encoding_aes_key, appid)
    @token, @encoding_aes_key, @appid = token, encoding_aes_key, appid
  end

  def build_encrypt_msg(xml_msg, timestamp, nonce)
    encrypted_msg = encrypt_msg(xml_msg)
    timestamp = timestamp.to_time.to_i.to_s
    signature = get_signature(encrypted_msg, timestamp, nonce)


    enc_msg_hash ={ Encrypt: encrypted_msg,
                    MsgSignature: signature,
                    TimeStamp: timestamp.to_i,
                    Nonce: nonce.to_s
    }
    # msg_hash = Hash.from_xml(xml_msg)
    # msg_hash = msg_hash['xml'].symbolize_keys
    # enc_msg_hash = compatible_version = msg_hash.merge(enc_msg_hash)

    XmlResp.new.build(enc_msg_hash)
  end

  def build_decrypt_msg(xml_msg, params)
    msg_hash = Hash.from_xml(xml_msg)
    msg_hash = msg_hash['xml'].symbolize_keys

    validate_signature(msg_hash[:Encrypt], params)

    plain_xml_msg = decrypt_msg(msg_hash[:Encrypt])
  end


  # private
  def encrypt_msg(msg)
    text = rand_str(16) + net_endian_pack(msg.size) + msg + @appid.to_s
    text = Pkcs7.new.encode(text)
    text = aes_encrypt(text)
    Base64.encode64(text)
  end

  def decrypt_msg(encrypted_msg)
    text = Base64.decode64(encrypted_msg)
    text = aes_decrypt(text)
    text = Pkcs7.new.decode(text)

    msg_size = net_endian_unpack(text[16...20])
    text = text[20..-1]

    appid = text[msg_size..-1]
    puts '==== appid matching:'
    ap(calcu: appid,
       orign: @appid,
       match: appid == @appid,
       msg_size: msg_size,
    )
    # raise "invalid appid: #{appid}" if @appid != appid

    msg = text.first(msg_size)
  end

  def validate_signature(encrypted_msg, params)
    params = params.symbolize_keys
    signature = get_signature(encrypted_msg, params[:timestamp], params[:nonce])
    msg_signature = params[:msg_signature]

    puts '==== message signature:'
    ap(calcu: signature,
       param: msg_signature,
       match: signature == msg_signature
    )

    # if signature != msg_signature
    #   raise %Q{invalid signature: unequal
    #         #{signature}
    #         !=
    #         #{msg_signature}
    #         }
    # end
  end

  def get_signature(encrypted_msg, timestamp, nonce)
    concat = [@token, timestamp, nonce, encrypted_msg].map(&:to_s).sort.join
    Digest::SHA1.hexdigest(concat)
  end

  def aes_encrypt(text)
    cipher = OpenSSL::Cipher::AES256.new('CBC')
    aes = cipher.encrypt
    aes.key = aes_key
    aes.update(text) + aes.final
  end

  def aes_decrypt(text)
    cipher = OpenSSL::Cipher::AES256.new('CBC')
    aes = cipher.decrypt
    aes.key = aes_key
    aes.update(text) + aes.final
  end

  def aes_key
    @aes_key ||= Base64.decode64(@encoding_aes_key+'=').tap do |key|
      unless key.size == 32
        raise "Invalid encoding_aes_key '#{@encoding_aes_key}': wrong length"
      end
    end
  end

  def net_endian_pack(integer)
    [integer].pack('N')
  end

  def net_endian_unpack(str)
    str.unpack('N').first
  end

  def rand_str(len)
    chars = ['a'..'z', 'A'..'Z', '0'..'9'].flat_map(&:to_a)
    len.times.map{chars.sample}.join
  end
end