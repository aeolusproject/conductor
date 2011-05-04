module Resources::DeploymentsHelper
  def count_uptime(start_time)
    result_string = []
    difference = Time.now.utc - start_time

    seconds    = difference % 60
    difference = (difference - seconds) / 60
    minutes    =  difference % 60
    difference = (difference - minutes) / 60
    hours      =  difference % 24
    difference = (difference - hours)   / 24
    days       =  difference % 7

    result_string<< pluralize(days.to_i, 'day') if days != 0
    result_string<<"#{"%02d"%hours.to_i}:#{"%02d"%minutes.to_i}:#{"%02d"%seconds.to_i}"
    result_string.join(", ")
  end
end
