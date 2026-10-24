# frozen_string_literal: true

# Ticketing: our self-hosted build enables every Enterprise feature without a token and
# hides the Enterprise markers and banners.
# - allows_to? is the gate for menus, controller guards, banners and views.
# - available_features / non_trialling_features feed the frontend (via /api/v3/configuration),
#   which shows its Enterprise icons for features missing there or marked as trialling.
# - hide_banners? is what the ee_hide_banners setting controls.
# active? is left alone: it would make OpenProject report and link to an Enterprise
# subscription we do not have.
module TicketingEnterpriseUnlock
  ALL_FEATURES = OpenProject::Token::FEATURES_PER_PLAN.values.reduce(:|)

  def allows_to?(_feature)
    true
  end

  def available_features
    ALL_FEATURES
  end

  def non_trialling_features
    ALL_FEATURES
  end

  def hide_banners?
    true
  end
end

Rails.application.config.to_prepare do
  EnterpriseToken.singleton_class.prepend(TicketingEnterpriseUnlock) unless EnterpriseToken.singleton_class < TicketingEnterpriseUnlock
end
