class Events < ActiveRecord::Migration
  def self.up
    drop_table :instance_events
    create_table :events do |t|
      t.integer    :source_id, :null => false
      t.string     :source_type, :null => false
      t.datetime   :event_time
      t.string     :status_code
      t.string     :summary
      t.string     :description
      t.timestamps
    end
  end

  def self.down
    drop_table :events
    create_table :instance_events do |t|
      t.integer    :instance_id, :null => false
      t.string     :event_type,  :null => false
      t.datetime   :event_time
      t.string     :status
      t.string     :message
      t.timestamps
    end
  end
end
