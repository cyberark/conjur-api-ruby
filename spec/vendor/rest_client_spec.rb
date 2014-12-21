# Copyright (C) 2014 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'spec_helper'
require 'tempfile'

# RestClient monkey patches MIME::Types, breaking it in certain situations.
# Let's make sure we monkey patch the monkey patch if necessary.

describe RestClient::Request do
  shared_examples :restclient do
    it "can be initialized" do
      expect { RestClient::Request.new method: 'GET', url: 'http://example.com' }.to_not raise_error
    end
  end

  def reinit_mime_types!
    # pretend to initialize MIME::Types from scratch
    MIME::Types.instance_variable_set :@__types__, nil
    MIME::Types.send :remove_const, :VERSION # to suppress a warning
    load 'mime/types.rb'
  end

  def with_env vals, &block
    olds = Hash[vals.keys.zip ENV.values_at *vals.keys]
    ENV.update vals
    yield if block_given?
    ENV.update olds
  end

  around do |ex|
    with_env 'RUBY_MIME_TYPES_CACHE' => cache,
        'RUBY_MIME_TYPES_LAZY_LOAD' => lazy.to_s do
      reinit_mime_types!
      ex.run
    end
  end

  context "with plain MIME::Types config" do
    let(:cache) { nil }
    let(:lazy) { false }
    include_examples :restclient
  end

  context "with lazy MIME::Types loading" do
    let(:cache) { nil }
    let(:lazy) { true }
    include_examples :restclient
  end

  context "using MIME::Types cache" do
    let(:cache) do
      tf = Tempfile.new('mimecache')
      path = tf.path

      tf.unlink # delete so mimetypes doesn't try to read it
      # create the cache
      with_env 'RUBY_MIME_TYPES_CACHE' => path,
          'RUBY_MIME_TYPES_LAZY_LOAD' => 'false' do
        reinit_mime_types!
      end

      return path
    end

    after { File.unlink cache }
    let(:lazy) { false }
    include_examples :restclient
  end
end
