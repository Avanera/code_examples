# task:
# implement a service to display timezine in required formats using TZInfo::Timezone
#
class TimezoneFetcher
  def self.get_timezone(timezone)
    TZInfo::Timezone.get(timezone.to_s)
  rescue TZInfo::InvalidTimezoneIdentifier
    nil
  end

  # timezone_with_offset format sample:
  # '(GMT +03:00) Europe/Moscow'
  def self.timezone_with_offset(timezone)
    timezone = get_timezone(timezone) if timezone.is_a?(String)
    return nil unless timezone

    timezone.strftime('(GMT %:z)').to_s + ' ' + timezone.canonical_identifier.to_s
  end
end
