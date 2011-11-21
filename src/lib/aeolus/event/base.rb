module Aeolus
  module Event
    class Base
      extend Aeolus::Event::Accessor
      attr_accessor :target, :event_id, :action

      # Base objects, or an implementor, can be initialized by passing in
      # a hash containing any attributes the caller wishes to set, including
      # #old_values=(hash).  Example:
      #   b = Aeolus:Event.Base.new({:owner => 'new',
      #                         {:old_values =>
      #                           {:owner => 'old'}}})
      def initialize(args={})
        set_defaults
        args.each do |k,v|
          if self.respond_to?(k)
            self.send(k.to_s+"=",v)
          end
        end
      end

      # Push the event to the configured output (target). Initial implementation
      # is a syslog convertor to back this method, but other targets can be added
      # over time, as needed.
      def process(output_target=nil, source='conductor', uuid=nil)
        @target = output_target unless output_target.nil?
        true
        # TODO: Call any required transformation methods to output properly to given targets
      end

      def attributes
        @attributes ||= []
        if @attributes.size == 0
          self.class.ancestors.each do |obj|
            @attributes = obj.respond_to?(:attributes)? @attributes + obj.attributes : @attributes
          end
        end
        return @attributes
      end

      # List the fields the caller has denoted as changed
      def changed_fields
        return [] unless old_values.respond_to?(:collect)
        old_values.collect {|k,v| k}
      end

      def old_values
        @old_hash
      end

      # Set the previous values for event attributes by passing in a hash.
      # For instance, if the caller of a given event wants to specify a new
      # owner (assuming that is a valid attribute for the event in question),
      # they would list the old owner either directly in the object creation
      # (see #initialize), or pass in a hash here like this:
      #   b.old_values({:owner => 'old'})
      def old_values=(val_hash)
        @old_hash = val_hash
      end

      protected
      def set_defaults
        @target = 'syslog'
        yield if block_given?
      end
    end
  end
end
