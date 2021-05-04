require 'active_support'
require 'spec_helper'

require 'helpers/errors_matcher'

require 'webrick'
require 'webrick/https'

describe 'SSL connection' do
  context 'with an untrusted certificate' do
    it 'fails' do
      expect { Conjur::API.login 'foo', 'bar', account: "the-account" }.to \
          raise_one_of(RestClient::SSLCertificateNotVerified, OpenSSL::SSL::SSLError)
    end
  end

  context 'with certificate added to the default OpenSSL cert store' do
    before do
      cert_store.add_cert(cert)
    end

    it 'works' do
      expect { Conjur::API.login 'foo', 'bar', account: "the-account" }.to raise_error RestClient::ResourceNotFound
    end
  end

  let(:server) do
    server = WEBrick::HTTPServer.new \
        Port: 0, SSLEnable: true,
        AccessLog: [], Logger: Logger.new('/dev/null'), # shut up, WEBrick
        SSLCertificate: cert, SSLPrivateKey: key
  end
  let(:port) { server.config[:Port] }
  let(:cert_store) { OpenSSL::X509::Store.new }

  before do
    # Reset configuration to allow each test to use its own stub
    # of OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE.
    Conjur.configuration = nil
    stub_const 'OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE', cert_store

    allow(Conjur.configuration).to receive(:authn_url).and_return "https://localhost:#{port}"
  end

  around do |example|
    server_thread = Thread.new do
      server.start
    end
    example.run
    server.shutdown
    server_thread.join
  end

  let(:cert) do
    OpenSSL::X509::Certificate.new """
      -----BEGIN CERTIFICATE-----
      MIIDCzCCAfOgAwIBAgIUaApjB95cJZlMTwDg4EBk4Mf1y4swDQYJKoZIhvcNAQEL
      BQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MCAXDTIxMDQyODIxNTA1OFoYDzQ3NTkw
      MzI1MjE1MDU4WjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwggEiMA0GCSqGSIb3DQEB
      AQUAA4IBDwAwggEKAoIBAQC+MIx1LCzBeAl7kHfI21wYmA6W8luyq14+DecaQPMd
      bW7fMlHSMJC/nlFDQyqmfYfKlVCiJRV/QTdUtA9hCytPlEKjlVmm4WIYLKfjj8Sp
      A+X9VURk75Fz+Z7UsF8u2J3pF9wFfhBzznwePlFdcWYyQMIRtghoHk/WSsbJVXVQ
      so7+0BLFyMYB3otfCyK+H/iyoXWLZll2irYZJedVm/lyTlnc9dT1XDAWWI8kSeUV
      lCkEulqOf8qZyU7wNUafRkzBuYkR7ddp1Qdkq+QYw7blmfZXyJbAYSt4gEMyDMk8
      ArScP8j+Efz5D54wS7fZFwmQp41+iP5WTxGsSU3dh44fAgMBAAGjUzBRMB0GA1Ud
      DgQWBBS4ZJDxXOs8rK3+SyfLopDFqK0IWDAfBgNVHSMEGDAWgBS4ZJDxXOs8rK3+
      SyfLopDFqK0IWDAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQAE
      WuzjqQ/gyho/pluX31hq7EMAFgqqz7ECN6DqmvpqabMD6s1kQ662KTo7gCBEcNtA
      nC7QycFp4v/Cr8+aUEa1W3+q2MqbmshORonUrLE/vxejK+NUvhSCWnmrM8v60zhR
      pn9lSSgQCBKWDgaU0VQVn0I9MuexeAj64Qv2uUHnZK3QUx+Gk3uurTmhKEN5FI+D
      sC7xO0qquTZ1Vv1EkLEso4dnFVW84EjdfmfeiW6JmHO7z1p1ebGsRwoQead/qTKw
      ze+Y1A1w3GzuhDo55aHlWE/Wvnou0aM3O9gUd++a2j+XJ2P7qaTB/L7SJk4qZ9RA
      t2PbKVP+tyZjXKtXmgzp
      -----END CERTIFICATE-----
    """.lines.map(&:strip).join("\n")
  end

  let(:key) do
    OpenSSL::PKey.read """
      -----BEGIN RSA PRIVATE KEY-----
      MIIEowIBAAKCAQEAvjCMdSwswXgJe5B3yNtcGJgOlvJbsqtePg3nGkDzHW1u3zJR
      0jCQv55RQ0Mqpn2HypVQoiUVf0E3VLQPYQsrT5RCo5VZpuFiGCyn44/EqQPl/VVE
      ZO+Rc/me1LBfLtid6RfcBX4Qc858Hj5RXXFmMkDCEbYIaB5P1krGyVV1ULKO/tAS
      xcjGAd6LXwsivh/4sqF1i2ZZdoq2GSXnVZv5ck5Z3PXU9VwwFliPJEnlFZQpBLpa
      jn/KmclO8DVGn0ZMwbmJEe3XadUHZKvkGMO25Zn2V8iWwGEreIBDMgzJPAK0nD/I
      /hH8+Q+eMEu32RcJkKeNfoj+Vk8RrElN3YeOHwIDAQABAoIBAQCnW0ctkDqt3/fQ
      MHcHWue2iI9GCmvgU+WxC0DSHFcSDQrkAn53S98DjseJPaBZMtr7y9pRY/p/qR6M
      PYnO5iotc5QUKEbkjy1nglwV5Zuy8kg+XPq7Kwg+GmjGVZDcQybpRuKIPr8xeIBF
      iKbGaBP6ontjZGAPZqTwN4qm/bkm0QRQkMEVQLpBaOlXjl0BCknhCMgyNA1F0jGc
      HLqJpFO46qvWDkDaKriMY/ezrkGYxlvV8xGJ2lzoaNWBsQeMXtcDJXuFMJO3lZl4
      VUjeNbyPprUzL6/kLZGMVFdRWhzKAluJEy3B6zybY4xxmgmifqn8/OxIaT172IXN
      KACuEorpAoGBAOYZEfuON+73dcstpjq3062+XUOxAAc77aFcGFQ2pqDTUtvoR05R
      o0uXrSuQqt0/FJVdZqdDx1and6idI7j/LfkOwvmPPg2dJIwKV73T2HdR7BpJaYlI
      KS6Bgl0AiW2ibjZJbBFJMiINb2tRGeYcOPfWlis309D2DXxl1f1TJTKTAoGBANOZ
      aDH1VJXh7rdAHrwNonTjoCeYKG7oAh0WTfqmCqcBjAkXsVc7dBd/98XKGS5LPRtl
      dIaJdYngeYyH5Ey5O2l/63tk0d4sqE8l+GVy+OHFn2AZMuaVXS0JXIQspn4s/U7F
      CuawmFszE8fv41WgVNhF00ijheoRz/X19yu0ULHFAoGAYmJZ1AutUtowXZ25M+Yh
      9motCqKF9pHjO1lbdbagbKevCCQ7SPuTLOE/xB7pUAyGyo7TM7XBaAXXHhuCiLlj
      eNic+YQL7lpApDhP5/TK28oFf//fxjk6ko4Bpa5zFJOdOE0QjhuT+gdwmpxkzIVI
      vn/cWcJXKUPr5ELOyrBgeU0CgYBWqIUbsLWrjJQPSJtNuOfHp1F35cDpausyrmfR
      Nx81tlR7hNCEQT0SQr5eqp4Vb4rfJXXLg5A3n08oVp8RLOtAEbuHFYs9ylxDzfEk
      2ylCjYTv/mHyPUmjoCnbl8237wTutZP5VmmPMCPxxjT8ZGVbDX2ySgYWDqV0vf80
      TuydYQKBgG24Wpes1CJmKiuWGnPi5I/+iIKZRfpEGidpjnsktkr3O+VZSZNQtDfC
      uWp/NgMxzxXxYdmmaQTwektB5axrsPUnxxiHmb8KkVU1IcMpYvUulFYiKVvFx+JJ
      bx/fkItCZ4AP3CG2Onz8xZdosg+c+MEdIlCrg94dA1EmHewCt2Hv
      -----END RSA PRIVATE KEY-----
    """.lines.map(&:strip).join("\n")
  end
end
