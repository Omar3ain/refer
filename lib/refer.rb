require "refer/version"
require "refer/engine"
require "securerandom"

module Refer
  include ActiveSupport::Configurable

  autoload :Controller, "refer/controller"
  autoload :HasReferrals, "refer/has_referrals"
  autoload :Model, "refer/model"

  mattr_accessor :code_generator
  mattr_accessor :cookie_length
  mattr_accessor :cookie_name
  mattr_accessor :param_name
  mattr_accessor :overwrite_cookie
  mattr_accessor :track_visits
  mattr_accessor :mask_ips
  mattr_accessor :referral_completed

  # Set default values
  self.code_generator = ->(referrer) { SecureRandom.alphanumeric(8) }
  self.cookie_length = 30.days
  self.cookie_name = :refer_code
  self.param_name = :ref
  self.overwrite_cookie = true
  self.track_visits = true
  self.mask_ips = true

  class Error < StandardError; end
  class AlreadyReferred < Error; end

  def self.referred?(referee)
    Referral.where(referee: referee).exists?
  end

  def self.refer(code:, referee:)
    return if referred?(referee)
    ReferralCode.find_by(code: code)&.referrals&.create(referee: referee)
  end

  def self.refer!(code:, referee:)
    raise AlreadyReferred, "#{referee} has already been referred" if referred?(referee)
    ReferralCode.find_by!(code: code).referrals.create!(referee: referee)
  end

  def self.cookie(code)
    {
      value: code,
      expires: Refer.cookie_length.from_now
    }
  end

  # From Ahoy gem: https://github.com/ankane/ahoy/blob/v5.1.0/lib/ahoy.rb#L133-L142
  def self.mask_ip(ip)
    return ip unless mask_ips

    addr = IPAddr.new(ip)
    if addr.ipv4?
      # set last octet to 0
      addr.mask(24).to_s
    else
      # set last 80 bits to zeros
      addr.mask(48).to_s
    end
  end
end

ActiveSupport.run_load_hooks(:refer, Refer)