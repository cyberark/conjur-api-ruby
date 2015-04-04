#
# Copyright (C) 2015 Conjur Inc
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
#
module Conjur

  # A Graph represents a directed graph of roles.
  #
  # An instance of this class is returned by {Conjur::API#role_graph}.
  #
  # @example Graphs act like arrays of edges
  #   graph.each do |edge|
  #     puts "#{edge.parent} -> #{edge.child}"
  #   end
  #   # role1 -> role2
  #   # role2 -> role3
  #
  class Graph

    include Enumerable

    # @!attribute r edges
    #   @return [Array<Conjur::Graph::Edge>] the edges of this graph
    attr_reader :edges

    # @api private
    #
    # @param val [String, Hash, Array, Graph] Data from which to initialize the instance
    def initialize val
      @edges = case val
        when String then JSON.parse(val)['graph']
        when Hash then val['graph']
        when Array then val
        when Graph then val.edges
        else raise ArgumentError, "don't know how to turn #{val}:#{val.class} into a Graph"
      end.map{|pair| Edge.new(*pair) }.freeze
      @next_node_id = 0
      @node_ids = Hash.new{ |h,k| h[k] = next_node_id }
    end

    # Enumerates the edges of this graph.
    # @yieldparam [Conjur::Graph::Edge] each edge of the graph
    # @return [Conjur::Graph] this graph
    def each_edge
      return enum_for(__method__) unless block_given?
      edges.each{|e| yield e}
      self
    end

    alias each each_edge

    # Enumerates the vertices (roles) of this graph
    # @yieldparam vertex [Conjur::Role] each vertex in this graph
    # @return [Conjur::Graph] this graph
    def each_vertex
      return enum_for(__method__) unless block_given?
      vertices.each{|v| yield v}
    end

    # Serialize the graph as JSON
    # @param [Boolean] short when true, the graph is serialized as an array of arrays instead of an array of hashes.
    # @return [String] the JSON serialized graph.
    # @see #as_json
    #
    def to_json short =  false
      as_json(short).to_json
    end

    def as_json short = false
      edges = self.edges.map{|e| e.as_json(short)}
      short ? edges : {'graph' => edges}
    end

    # Returns a string formatted for use by the {http://www.graphviz.org/ graphviz dot} tool.
    #
    # @param [String, NilClass] name to assign to the graph. Usually this can be omitted unless you
    #   are writing multiple graphs to a single file.  Must be in the ID format specified by
    #   http://www.graphviz.org/content/dot-language
    # @return [String] the dot format (used by graphviz, among others) representation of this graph.
    def to_dot name = nil
      dot = "digraph #{name || ''} {"
      vertices.each do |v|
        dot << "\n\t" << dot_node(v)
      end
      edges.each do |e|
        dot << "\n\t" << dot_edge(e)
      end
      dot << "\n}"
    end

    # Return the vertices (roles) of the graph as an array.
    # @return [Array<Conjur::Role>] the vertices/roles
    def vertices
      @vertices ||= edges.inject([]) {|a, pair| a.concat pair.to_a }.uniq
    end

    alias roles vertices

    private

    def node_id_for role
      role = role.id if role.respond_to?(:id)
      @node_ids[role]
    end

    def next_node_id
      id = @next_node_id
      @next_node_id += 1
      "node_#{id}"
    end

    def node_label_for role
      role = role.id if role.respond_to? :id
      if single_account?
        role = role.split(':', 2).last
        if single_kind?
          role = role.split(':', 2).last
        end
      end
      role
    end

    def single_account?
      if @single_account.nil?
        @single_account = roles.map do |role|
          role = role.id if role.respond_to?(:id)
          role.split(':').first
        end.uniq.size == 1
      end
      @single_account
    end

    def single_kind?
      if @single_kind.nil?
        return @single_kind = false unless single_account?
        @single_kind = roles.map do |role|
          role = role.id if role.respond_to?(:id)
          role.split(':')[1]
        end.uniq.size == 1
      end
      @single_kind
    end

    def dot_node v
      id = node_id_for v
      label = node_label_for v
      "#{id} [label=\"#{label}\"]"
    end

    def dot_edge e
      parent_id = node_id_for(e.parent)
      child_id = node_id_for(e.child)
      "#{parent_id} -> #{child_id}"
    end

    # Represents a directed Edge between a parent role and a child role.
    #
    # In this context, the parent role is a *member of* the child role.  For example,
    # the `admin` role is a parent of every role, either directly or indirectly, because
    # it is added as a member to all roles it creates.
    class Edge

      # Return the parent of this edge. The {#parent} role *is a member of* the {#child} role.
      # @return [Conjur::Role] the parent role
      attr_reader :parent

      # Return the child of this edge.  The {#parent} role *is a member of* the {#child} role.
      # @return [Conjur::Role] the child role
      attr_reader :child

      # Create a directed edge with a parent and child
      #
      # @param [Conjur::Role] parent the parent or source of this edge
      # @param  [Conjur::Role] child the child or destination of this edge
      def initialize parent, child
        @parent = parent
        @child = child
      end

      # Serialize this edge as JSON.
      #
      # @see #as_json
      # @param [Boolean] short when true, serialize the edge as an Array instead of a Hash
      # @return [String] the JSON serialized edge
      def to_json short = false
        as_json(short).to_json
      end

      # Return a value suitable for JSON serialization.
      #
      # The `short` parameter determines whether to return a `["parent", "child"]` Array
      # or a Hash like `{"parent" => "parent-role", "child" => "child-role"}`.
      #
      # @param [Boolean] short return an Array when true, otherwise return a Hash.
      # @return [Array, Hash] value suitable for JSON serialization
      def as_json short = false
        short ? to_a : to_h
      end

      # Return this edge as a Hash like {"parent" => "...", "child" => "..."}.
      #
      # Note that the keys in the hash are strings.
      #
      # @return [Hash] a Hash representing this edge
      def to_h
        # return string keys to make testing less brittle
        {'parent' => @parent, 'child' => @child}
      end

      # Return this edge as an Array like ["parent", "child"]
      #
      # @return [Array<String>] the edge as an Array
      def to_a
        [@parent, @child]
      end

      # @api private
      # :nodoc:
      def to_s
        "<Edge #{parent.id} --> #{child.id}>"
      end

      # Support using edges as hash keys
      # @api private
      # :nodoc:
      def hash
        @hash ||= to_a.map(&:to_s).hash
      end

      # Support using edges as hash keys and equality testing
      # @api private
      # :nodoc:
      def == other
        other.kind_of?(self.class) and other.parent == parent and other.child == child
      end

      alias eql? ==
    end

  end
end
