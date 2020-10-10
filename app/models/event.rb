class Event < ApplicationRecord
  belongs_to :user

  
  def  self.upcoming_event(evnt)
    event = evnt.date.split('/')
    evnt_month = event[0].to_i
    evnt_day = event[1].to_i
    evnt_year = event[3].to_i

    today_date = Date.today.strftime()
    today_date = today_date.split('-')
    curr_day = today_date[2].to_i
    curr_month = today_date[1].to_i
    curr_year = today_date[0].to_i
    result = false
    
    if evnt_day > curr_day && evnt_month == curr_month && evnt_year == curr_year
      result = true
    elsif  evnt_month > curr_month && evnt_year >= curr_year
      result = true
    elsif evnt_day >= curr_day && evnt_month > curr_month && evnt_year >= curr_year
      result = true
    elsif evnt_day > curr_day && evnt_month >= curr_month && evnt_year >= curr_year
      result = true 
    elsif evnt_day < curr_day && evnt_month <= curr_month && evnt_year > curr_year
      result = true
    elsif evnt_day > curr_day && evnt_month <= curr_month && evnt_year > curr_year
      result = true
    end
    
    result
  end
end
