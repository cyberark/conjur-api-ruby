require 'spec_helper'
require 'helpers/request_helpers'

describe Conjur::API, api: :dummy do
  include RequestHelpers
  subject { api }

  describe 'role_graph' do
    let(:roles){ [ 'acct:user:alice', 'acct:user:bob', 'acct:user:eve' ] }
    let(:options){ {} }
    let(:current_role){ 'some-role' }
    let(:graph){
      [
          [ 'acct:user:alice', 'acct:user:eve' ],
          [ 'acct:user:bob',   'acct:user:eve']
      ]
    }
    let(:response){ {
        graph: graph
    }.to_json }

    let(:graph_edges){
      graph.map{|e| Conjur::Graph::Edge.new *e}
    }

    before do
      allow(api).to receive(:current_role).and_return current_role
    end

    subject{ api.role_graph roles, options }

    def role_graph_url_for roles, options, current_role
      qs = options.reverse_merge(ancestors: true, descendants: true)
             .merge(from_role: current_role, roles: roles).slice(:from_role, :ancestors, :descendants, :roles).to_query
      "http://authz.example.com/#{account}/roles?#{qs}"
    end

    def expect_request_with_params params={}
      expect_request(headers: credentials[:headers], method: :get,
                     url: role_graph_url_for(roles, options, current_role))
        .and_return(response)
    end

    it "gets /roles with the correct params" do
      expect_request_with_params ancestors: true, descendants: true, from_role: current_role
      subject
    end

    context "when options[:ancestors] and options[:descendants] are false" do
      let(:options){ { ancestors: false, descendants: false } }
      it "gets /roles with the correct params" do
        expect_request_with_params ancestors: false, descendants: false, from_role: current_role
        subject
      end
    end

    context "when given options[:as_role] = 'foo'" do
      it "sets the from_role param to 'foo'" do
        expect_request_with_params from_role: 'foo'
        subject
      end
    end

    describe "the result" do
      it "is a Conjur::Graph" do
        expect_request_with_params
        expect(subject).to be_kind_of(Conjur::Graph)
      end
      it "has the right edges" do
        expect_request_with_params
        expect(subject.edges.to_set).to eq(graph_edges.to_set)
      end
    end

  end

  describe '#role_name_from_username' do

    before {
      allow(api).to receive(:username) { username }
    }
    context "username is" do
      [
        [ 'the-user', 'user:the-user' ],
        [ 'host/the-host', 'host:the-host' ],
        [ 'host/a/quite/long/host/name', 'host:a/quite/long/host/name' ],
        [ 'newkind/host/name', 'newkind:host/name' ],
      ].each do |p|
        context "'#{p[0]}'" do
          let(:username) { p[0] }

          describe '#role_name_from_username' do
            subject { super().role_name_from_username }
            it { is_expected.to eq(p[1]) }
          end
        end
      end
    end
  end
end
