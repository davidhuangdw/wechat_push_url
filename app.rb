require 'sinatra'
require 'sinatra/base'
require 'json'
require 'active_support/all'
require 'awesome_print'
require './lib/xml_resp'
require './lib/encrypt'

class PushUrl < Sinatra::Base
  ENCODING_AES_KEY = 'I97Y6pmHU56mx5TAHdaJTSsV9bylieHJlhYI2GCMKj6'
  APP_ID = 'wx896e08f0cac4122b'
  TOKEN = 'david'

  before do
    puts '==== request:'
    req_body = nil
    info = request.instance_eval do
      req_body = body.read
      {method: request_method,
       url: url,
       query_string: query_string,
       body: req_body,
      }
    end
    ap info
    puts '==== params:'
    ap params

    @body = req_body
  end

  get '/hi' do
    'hello push_url!'
  end

  get '/receive' do
    params['echostr']
  end

  post '/receive' do
    body_hash = Hash.from_xml(@body)
    msg_hash = body_hash['xml'].symbolize_keys

    puts '==== request body:'
    ap body_hash

    puts '==== signature:'
    token = TOKEN
    timestamp, nonce = params.values_at(*%w[timestamp nonce])
    calc_sig = signature(token, timestamp, nonce)
    params_sig = params['signature']
    ap(params_sig: params_sig,
       calc_sig: calc_sig,
       equal: params_sig == calc_sig)


    if params['encrypt_type'] == 'aes'
      encrypt = Encrypt.new(TOKEN, ENCODING_AES_KEY, APP_ID)
      plain_xml_msg = encrypt.build_decrypt_msg(@body, params)

      plain_msg_hash = Hash.from_xml(plain_xml_msg)
      msg_hash = plain_msg_hash['xml'].symbolize_keys

      puts '==== decrypted_msg_hash:'
      ap plain_msg_hash
      ap msg_hash

      resp = auto_reply(msg_hash)
      puts '==== origin resp:'
      puts resp

      resp = encrypt.build_encrypt_msg(resp, Time.now, '1234')
    else
      resp = auto_reply(msg_hash)
    end

    puts '==== resp:'
    puts resp
    puts '==== resp_end'
    resp
    # resp = ''
  end

  private
  def auto_reply(msg_hash)
    # return '' if msg_hash[:MsgType]=='event' && msg_hash[:Event]=='LOCATION'
    XmlResp.new.build(ToUserName: msg_hash[:FromUserName],
                      FromUserName: msg_hash[:ToUserName],
                      CreateTime: Time.now.to_i,
                      MsgType: 'text',
                      # MsgType: 'transfer_customer_service',
                      Content: "Hello, your msg is:\n\n#{@body.gsub(']]>', ']] >')}\n"
    )
  end

  def signature(token, timestamp, nonce)
    checksum = [token, timestamp, nonce].sort.join
    Digest::SHA1.hexdigest(checksum)
  end
end
