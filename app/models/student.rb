class Student < ApplicationRecord

  belongs_to :study_year
  belongs_to :department
  has_many :payments
  has_many :paid_payments, -> { not_refunded }, class_name: 'Payment'
  has_many :memberships, through: :paid_payments, source: :payable, source_type: 'Membership'
  has_many :active_memberships, -> { active }, through: :paid_payments, source: :payable, source_type: 'Membership', class_name: 'Membership'
  has_many :weis, through: :paid_payments, source: :payable, source_type: 'Wei'
  has_many :wei_registrations
  has_many :cards

  scope :members, -> { joins(:memberships).where('memberships.start_date <= ? AND memberships.end_date >= ?', Date.today, Date.today) }
  scope :non_members, -> { where.not(id: members) }

  validates_presence_of :first_name, :last_name, :gender, :email, :birthday
  validates_uniqueness_of :student_id, if: -> (student) { not student.student_id.nil? and not student.student_id.empty? }
  validates_inclusion_of :gender, in: %w(M W)

  phony_normalize :phone, default_country_code: 'FR'
  validates_plausible_phone :phone, default_country_code: 'FR'

  scope :minors, -> { where('birthday > ?', 18.years.ago) }

  def card
    card = cards.order(:created_at).last
    if card.nil?
      ''
    else
      card.code
    end
  end

  def card=(card)
    if card.class == Card
      cards << card unless cards.include? card
    else
      c = cards.find_by_code card
      if c and c.student.id == id
        c.update! created_at: Time.now
      else
        cards.create! code: card
      end
    end
  end

  def minor?
    birthday > 18.years.ago
  end

  def member?
    active_memberships.length > 0
  end

  def available_memberships
    if member?
      Membership.where 'id < ?', 0
    else
      Membership.where('end_date > ?', Date.today).where.not(id: memberships)
    end
  end

  scope :search_with, -> (query) do
    request = all
    query.to_s.downcase.split(' ').each do |q|
      e = "%#{I18n.transliterate(q)}%"
      r = %w(first_name last_name).map {|f|"translate(LOWER(students.#{f}),'¹²³áàâãäåāăąÀÁÂÃÄÅĀĂĄÆćčç©ĆČÇĐÐèéêёëēĕėęěÈÊËЁĒĔĖĘĚ€ğĞıìíîïìĩīĭÌÍÎÏЇÌĨĪĬłŁńňñŃŇÑòóôõöōŏőøÒÓÔÕÖŌŎŐØŒř®ŘšşșßŠŞȘùúûüũūŭůÙÚÛÜŨŪŬŮýÿÝŸžżźŽŻŹ','123aaaaaaaaaaaaaaaaaaacccccccddeeeeeeeeeeeeeeeeeeeeggiiiiiiiiiiiiiiiiiillnnnnnnooooooooooooooooooorrrsssssssuuuuuuuuuuuuuuuuyyyyzzzzzz') LIKE ?"} .join ' OR '
      request = request.where(
          "#{r} OR students.student_id LIKE ? OR students.email LIKE ?",
          e,e,e,q
      )
    end
    request
  end

  def wei_registration
    wei_registrations.where(wei: Wei.current)
  end

  def name
    "#{first_name.capitalize} #{last_name.upcase}"
  end

end
