require 'sinatra'
require 'sinatra/base'
require 'json'
require 'active_support/all'
require 'awesome_print'
require './lib/xml_resp'

class PushUrl < Sinatra::Base
  before do
    puts "==== request:"
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
    puts "==== params:"
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
    msg = body_hash['xml'].symbolize_keys

    puts "==== request body:"
    ap body_hash

    puts "==== signature:"
    token = 'david'
    timestamp, nonce = params.values_at(*%w[timestamp nonce])
    calc_sig = signature(token, timestamp, nonce)
    params_sig = params['signature']
    ap(params_sig: params_sig,
       calc_sig: calc_sig,
       equal: params_sig == calc_sig)

    resp = auto_reply(msg)
    puts "==== resp:"
    puts resp
    puts "==== resp_end"
    resp
    # resp = ''
  end

  private
  def auto_reply(msg)
    # return '' if msg[:MsgType]=='event' && msg[:Event]=='LOCATION'
    XmlResp.new.build(ToUserName: msg[:FromUserName],
                      FromUserName: msg[:ToUserName],
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
