# == Schema Information
#
# Table name: work_units
#
#  id         :integer(4)      not null, primary key
#  project_id :integer(4)
#  user_id    :integer(4)
#  start_time :datetime
#  stop_time  :datetime
#  hours      :decimal(8, 2)
#  notes      :string(255)
#  invoice_id :integer(4)
#  bill_id    :integer(4)
#  created_at :datetime
#  updated_at :datetime
#  billable   :boolean(1)      default(TRUE)
#

class WorkUnit < ActiveRecord::Base

  scope :in_progress, :conditions => [ "hours IS NULL and start_time IS NOT NULL" ]
  scope :completed, :conditions => [ "hours IS NOT NULL" ]
  scope :recent, :limit => 8, :order => "stop_time DESC"

  scope :billable, :conditions => { :billable => true }

  scope :unbilled, :conditions => { :bill_id => nil, :billable => true }
  scope :uninvoiced, :conditions => { :invoice_id => nil, :billable => true }
  scope :billed, :conditions => "bill_id IS NOT NULL"
  scope :invoiced, :conditions => "invoice_id IS NOT NULL"

  scope :unbillable, :conditions => { :billable => false }


  scope :for_project, lambda {|project|
    { :conditions => {:project_id => project.self_and_descendants.map{ |p| p.id } } }
  }
  scope :for_project_exclusive, lambda { |project|
    { :conditions => { :project_id => project.id }}
  }
  scope :for_client, lambda { |client|
    projects = client.projects.map{ |p| p.self_and_descendants.map{|q| q.id } }.flatten.uniq
    { :conditions => { :project_id => projects }}
  }

  scope :today, lambda { { :conditions => [ "stop_time > ? ", Time.zone.now.to_date ] } }
  scope :in_last, lambda { |num_days| { :conditions => [ "stop_time > ? ", (Time.zone.now - num_days.days).to_date ] } }
  attr_accessible :project_id, :project, :notes, :start_time, :stop_time, :hours, :billable

  belongs_to :user
  belongs_to :project

  validates_presence_of :project_id
  validates_presence_of :user_id
  validates_presence_of :start_time

  # can't have a stop time without hours also specified
  validates_presence_of :hours, :if => Proc.new{ |wu| wu.stop_time }

  # A work unit is in progress if it has been started
  # but does not have hours yet.
  def in_progress?
    start_time && !hours
  end

  def completed?
    !in_progress?
  end

  def invoiced?
    !invoice_id.nil?
  end

  def billed?
    !bill_id.nil?
  end

  # TODO: spec this method
  def clock_out!
    # debugger
    self.stop_time ||= Time.now
    self.hours ||= WorkUnit.decimal_hours_between(self.start_time, self.stop_time)
    self.truncate_hours!
    save!
  end

  # def project_id=(value)
  #   self.write_attribute(:project_id, value)
  #   self.billable= project.billable if project
  # end

  # TODO: spec this method
  # compute the number of hours (as a decimal) between
  # two times
  HOUR_DECIMAL = BigDecimal.new("3600.00")
  def self.decimal_hours_between(start, stop)
    start_decimal = BigDecimal.new(start.to_i.to_s)
    stop_decimal = BigDecimal.new(stop.to_i.to_s)
    diff = stop_decimal - start_decimal
    (diff / HOUR_DECIMAL).round(2)
  end

  def truncate_hours!
    unless self.hours.nil? || self.start_time.nil? || self.stop_time.nil?
      self.hours = [self.hours, WorkUnit.decimal_hours_between(self.start_time, self.stop_time)].min
    end
  end

  validate :validate_integrity
  # Users are not allowed to have two work units in progress simultaneously.
  def validate_integrity
    if in_progress? && (@other = user.current_work_unit) && @other != self
      errors.add_to_base "You may not clock in twice at the same time."
    end
    if stop_time && start_time && hours
      if hours > WorkUnit.decimal_hours_between(start_time, stop_time)
        errors.add_to_base("Hours must not be greater than the difference between start and stop times.")
      end
    end
    errors.add(:hours, "must be greater than 0.00") if hours and hours <= 0.0
    errors.add_to_base("Completed work units must have a stop time") if (hours && !stop_time)
    # errors.add(:notes, "are required for work units over 30 minutes") if hours && (hours > 0.5)  && notes.blank?
    errors.add(:stop_time, "must not be in the future") if stop_time && stop_time > Time.now
    errors.add(:start_time, "must not be in the future") if start_time && start_time > Time.now
  end


  after_validation_on_create :set_defaults
  def set_defaults
    # debugger
    self.billable = project.billable if project
  end
end