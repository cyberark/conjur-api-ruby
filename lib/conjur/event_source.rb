module Conjur
  # An EventSource instance is used to parse a stream in the format given by
  # the Server Sent Events standard: http://www.whatwg.org/specs/web-apps/current-work/#server-sent-events
  class EventSource
    class Event < Struct.new(:data, :name, :id);
    end

    # @!attribute retry [r]
    #   @return [Fixnum] the last retry field received, or nil if no retry fields 
    #   have been received.
    attr_reader :retry

    # @!attribute last_event_id [r]
    #   @return [String] the id of the last fully received event, or nil if no 
    #   events have been received containing an id field.
    attr_reader :last_event_id

    # @!attribute json [rw]
    #   @return [Boolean] (true) Whether to parse event's data field as JSON.
    attr_accessor :json
    alias json? json

    def initialize
      @json   = true
      @on     = {}
      @all    = []
      @buffer = ""
    end

    # Feed a chunk of data to the EventSource and dispatch any fully receieved
    # events.  
    # @param [String] chunk the data to parse
    def feed chunk
      @buffer << chunk

      while i = @buffer.index("\n\n")
        process_event @buffer.slice!(0..i)
      end
    end

    # Adds a listener for :name:
    def on name, &block
      (@on[name.to_sym] ||= []) << block
    end

    # Listens to all messages
    def message &block
      @all << block
    end

    protected
    def process_event s
      data, id, name = [], nil, nil
      s.lines.map(&:chomp).each do |line|
        field, value = case line
          when /^:/ then
            next # comment, do nothing
          when /^(.*?):(.*)$/ then
            [$1, $2]
          else
            [line, ''] # this is what the spec says, I swear!
        end
        # spec allows one optional space after the colon
        value = value[1..-1] if value.start_with? ' '
        case field
          when 'data' then
            data << value
          when 'id' then
            id = value
          when 'event' then
            name = value.to_sym
          when 'retry' then
            @retry = value.to_i
        end
      end
      @last_event_id = id
      dispatch_event(data.join("\n"), id, name) unless data.empty?
    end

    def dispatch_event data, id, name
      data  = JSON.parse(data) if json?
      name  = (name || :message).to_sym
      event = Event.new(data, name, id)
      ((@on[name] || []) + @all).each { |p| p.call event }
    end

  end
end