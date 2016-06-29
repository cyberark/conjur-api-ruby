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
  let(:edges_with_admin) { edges.each {|e| e.push(false)} }

  let(:short_json_graph){ edges.to_json }
  let(:long_edges){ edges.map{|e| {'parent' => e[0], 'child' => e[1]}} }
  let(:long_hash_graph){ {'graph' => long_edges} }
  let(:long_json_graph){ long_hash_graph.to_json }

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
    it "contains all unique members of edges" do
      expect(subject.to_set).to eq(edges.flatten.uniq.to_set)
    end
  end

  describe "#to_dot" do
    let(:name){ nil }
    subject{ Conjur::Graph.new(edges).to_dot(name) }
    before do
      File.write('/tmp/conjur-graph-spec.dot', subject)
    end

    let(:role_to_node_id) do
      {}.tap do |h|
        edges.flatten.uniq.each do |v|
          expect(subject =~ /^\s*([a-z][0-9a-z_\-]*)\s*\[label\="(#{v})"\]/i).to be_truthy
          h[$2] = $1
        end
      end
    end

    context "when given a name" do
      let(:name){ 'foo' }
      it "names the digraph" do
        expect(subject).to match(/\A\s*digraph\s+foo\s*\{/)
      end
    end

    it "defines all the vertices in the graph" do
      edges.flatten.uniq.each do |v|
        expect(subject).to match(/^\s*[a-z][0-9a-z_\-]*\s*\[label\="#{v}"\]/i)
      end
    end

    it "defines all the edges in the graph" do
      edges.each do |e|
        parent_id = role_to_node_id[e[0]]
        child_id  = role_to_node_id[e[1]]
        expect(subject).to match(/^\s*#{parent_id}\s*\->\s*#{child_id}/)
      end
    end
  end

  shared_examples "it creates a new Graph" do
    let(:arg) { graph_edges }
    let(:edge_objects){ graph_edges.map{|e| Conjur::Graph::Edge.new(*e) }}

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
      let(:arg){ {'graph' => graph_edges} }
      it_accepts_the_argument
    end

    describe "given a JSON string" do
      let(:arg){ {'graph' => graph_edges}.to_json }
      it_accepts_the_argument
    end
  end

  describe "Graph.new" do
    it_should_behave_like "it creates a new Graph" do
      let(:graph_edges) { edges }
    end
  end

  describe "Graph.new with admin_option present" do
    it_should_behave_like "it creates a new Graph" do
      let(:graph_edges) { edges_with_admin }
    end
  end

end
