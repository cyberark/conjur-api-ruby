require 'spec_helper'

describe Conjur::Graph do
  let(:edges){ [
    [ 'a', 'b' ],
    [ 'a', 'c'],
    [ 'c', 'd'],
    ['b', 'd'],
    [ 'd', 'e'],
    # make two connected components
    ['o', 'q'],
    ['x', 'o']
  ]}
  let(:hash_graph){ {'graph' => edges} }
  let(:json_graph){ hash_graph.to_json }
  let(:short_json_graph){ edges.to_json }
  let(:long_edges){ edges.map{|e| {parent: e[0], child: e[1]}} }
  let(:long_hash_graph){ {'graph' => long_edges} }
  let(:long_json_graph){ long_hash_graph.to_json }
  let(:edge_objects){ edges.map{|e| Conjur::Graph::Edge.new(*e) }}

  describe "json methods" do
    subject{described_class.new edges}
    it "converts to long json correctly" do
      expect(subject.to_json).to eq(long_json_graph)
      expect(subject.as_json).to eq(long_hash_graph)
    end

    it "converts to short json correctly" do
      expect(subject.to_json(true)).to eq(short_json_graph)
      expect(subject.as_json(true)).to eq(edges)
    end
  end

  describe "#vertices" do
    subject{Conjur::Graph.new(edges).vertices.to_set}
    it{ is_expected.to eq(edges.flatten.uniq.to_set) }
  end

  describe "Graph.new" do
    let(:arg){ edges }
    subject{ described_class.new arg }
    def self.it_accepts_the_argument
      it "accepts the argument" do
        expect(subject.edges.to_set).to eq(edge_objects.to_set)
      end
    end
    describe "given an array of edges" do
      it_accepts_the_argument
    end

    describe "given a hash of {'graph' => <array of edges>}" do
      let(:arg){ hash_graph }
      it_accepts_the_argument
    end

    describe "given a JSON string" do
      let(:arg){ json_graph }
      it_accepts_the_argument
    end
  end
end