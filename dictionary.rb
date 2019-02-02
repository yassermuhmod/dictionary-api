
# Copyright 2019 iAchieved.it LLC
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'sinatra'
require 'redis'
require 'json'
require 'securerandom'

class DictionaryApp < Sinatra::Base

  before do
    content_type 'application/json'

    @redis = Redis.new
  end

  # Create a New Dictionary
  post '/dictionary' do

    did = SecureRandom.uuid

    @redis.set(did, {id:  did}.to_json)

    status 201
    {
      "id":  did
    }.to_json

  end

  # Delete a Dictionary
  delete '/dictionary/:id' do

    did = params[:id]

    if @redis.get(did) then
      status 204
    else
      status 404
    end

  end

  # Get all Keys
  get '/dictionary/:id/keys' do

    if not params[:id]
      status 404
    end

    did = params[:id]

    if @redis.get(did) then
      dict = JSON.parse(@redis.get(did))

      status 200
      dict.to_json
    else
      status 404
    end
  end

  # Set a key-value
  post '/dictionary/:id/keys/:key' do

    request.body.rewind
    begin
      body = JSON.parse request.body.read
    rescue
      return {"error":"error"}.to_json
    end

    did = params[:id]
    value = body['value']

    if @redis.get(did) then

      dict = JSON.parse(@redis.get(did))
      dict[params[:key]] = value
      @redis.set(did, dict.to_json)
      status 200

    else
      status 404
    end
  end

  # Get a value
  get '/dictionary/:id/keys/:key' do
    if not params[:id] || params[:key] then
      return 404
    end

   did = params[:id]
   key = params[:key]

    if @redis.get(did) then

      dict = JSON.parse(@redis.get(did))

      v = dict[key]

      if v then
        status 200
        {value:  v}.to_json
      else
        status 404
      end

    else
      # No such dictionary
      status 404
    end

  end

  delete '/dictionary/:id/keys/:key' do

    did = params[:did]
    key = params[:key]

    if @redis.get(did)
      dict = @redis.get(did)
      dict.delete(key)
      @redis.set(did, dict.to_json)

      status 204

    end
  end


end