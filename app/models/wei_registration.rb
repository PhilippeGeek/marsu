class WeiRegistration < ApplicationRecord
  belongs_to :student
  belongs_to :wei
  belongs_to :wei_bungalow, counter_cache: true
  belongs_to :wei_bus, counter_cache: true

  scope :registered, -> {where(status: 'registered')}
  scope :waiting, -> {where(status: 'waiting').order(:registration_by)}

  scope :for_current_wei, -> {where(wei: Wei.current)}
  default_scope { for_current_wei }

  validates_inclusion_of :status, in: %w(registered waiting canceled to_refund)
  validates_inclusion_of :paid, in: [true, false]
  validates_presence_of :status, :student, :wei
  validate :check_wei_is_not_full, :check_paid_status_when_changed, :valid_bug_bungalow
  before_update :cancel_paid

  def self.ranks
    i= (Wei.current.validated_registrations.count - Wei.current.seats)
    r={}
    WeiRegistration.waiting.pluck('id').each do |e|
      i=i+1
      r[e]=i
    end
    r
  end

  def minor?
    (wei.date - student.birthday) <= ((18.years+1.day)/(3600*24))
  end

  private
  def cancel_paid
    if status_changed? and status == 'canceled' and paid
      self.paid = false
    end
  end

  def valid_bug_bungalow
    if wei_bungalow_id_changed? or wei_bus_id_changed?
      if status != 'registered'
        errors.add(:wei_bus, 'ne peut être affecté sans inscription validée.')
        errors.add(:wei_bungalow, 'ne peut être affecté sans inscription validée.')
      else
        # Check here bus and/or bungalow are not full, throw error
      end
    end
  end
  def check_wei_is_not_full
    if status_changed? and status == 'registered' and wei.full?
      errors.add(:status, 'ne peut pas être changé à Inscrit car le Wei est plein.')
    end
  end
  def check_paid_status_when_changed
    if paid_changed?
      if paid and not student.weis.include? wei
        errors.add(:paid, "n'est pas correcte, l'étudiant n'a pas le produit!")
      elsif not paid and student.weis.include? wei
        errors.add(:paid, "n'est pas correcte, l'étudiant a le produit!")
      end
    end
  end
end
