module Refer
  class Visit < ApplicationRecord
    belongs_to :referral_code, counter_cache: true

    before_save :normalize_ip!, if :ip_present?

    def self.from_request(request)
      new(
        ip: request.ip,
        user_agent: request.user_agent,
        referrer: request.referrer,
        referring_domain: (URI.parse(request.referrer).try(:host) rescue nil)
      )
    end

    def ip_present?
      ip.present?
    end

    def normalize_ip!
      Refer.mask_ip(ip)
    end

  end
end
