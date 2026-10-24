# frozen_string_literal: true

# Ticketing: our self-hosted build enables the Administration > Design page (custom logo,
# colours, themes) without an Enterprise token. Every gate for it (menu item, controller
# guard, page banner, applying the styles) goes through EnterpriseToken.allows_to?.
module TicketingDesignUnlock
  UNLOCKED_FEATURES = %w[define_custom_style].freeze

  def allows_to?(feature)
    UNLOCKED_FEATURES.include?(feature.to_s) || super
  end
end

Rails.application.config.to_prepare do
  EnterpriseToken.singleton_class.prepend(TicketingDesignUnlock) unless EnterpriseToken.singleton_class < TicketingDesignUnlock
end
