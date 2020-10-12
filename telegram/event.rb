require File.expand_path('../config/environment', __dir__)

require 'telegram/bot'

require 'rufus-scheduler'

scheduler = Rufus::Scheduler.new


TOKEN = '1173859008:AAH4z5gonpnQSnoL5OQvEcWcp1ROD05cYOs'

def displayMessage(message)
  Telegram::Bot::Client.run(TOKEN) do |bot|
    bot.api.send_message(chat_id: message.chat.id, text: "Type '/add' to add an event ")
    bot.api.send_message(chat_id: message.chat.id, text: "Type '/view_events' to view all events ")
    bot.api.send_message(chat_id: message.chat.id, text: "Type '/delete' to delete event created by you")
    bot.api.send_message(chat_id: message.chat.id, text: "Type '/notify' to get notify of an upcoming event ")
  end
end

def get_notify(message)
  scheduler = Rufus::Scheduler.new
  Telegram::Bot::Client.run(TOKEN) do |bot|
    if Event.event_lists.length > 0
      bot.api.send_message(chat_id: message.chat.id, 
      text: "You will get Notifications of upcoming events every 1 minute ")
      scheduler.every '1m' do
        bot.api.send_message(chat_id: message.chat.id, text: "..................................")
        bot.api.send_message(chat_id: message.chat.id, text: "UPCOMING EVENTS ")
        bot.api.send_message(chat_id: message.chat.id, text: "..................................")
        Event.event_lists.each do |event|
          bot.api.send_message(chat_id: message.chat.id, text: "Event Description:  #{event.description}")
          bot.api.send_message(chat_id: message.chat.id, text: "Event Date:  #{event.date}")
          bot.api.send_message(chat_id: message.chat.id, text: "_________________________")
        end
      end
    else 
      bot.api.send_message(chat_id: message.chat.id, text: "Sorry you have no upcoming event")
    end
   end
end



def remove_keyboard(message)
  Telegram::Bot::Client.run(TOKEN) do |bot|
    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
    bot.api.send_message(chat_id: message.chat.id, text: "Enter '/add' to enter event", reply_markup: kb)
  end
end

def display_event_as_key(message, event)
  Telegram::Bot::Client.run(TOKEN) do |bot|
    markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: event)
    bot.api.send_message(chat_id: message.chat.id, text: "display", reply_markup: markup)
  end
end


Telegram::Bot::Client.run(TOKEN, logger: Logger.new($stderr)) do |bot|
  bot.logger.info('Bot has been started')

  bot.listen do |message|

    if !User.exists?(telegram_id: message.from.id)
      user = User.create(telegram_id: message.chat.id, name: message.from.first_name, 
      email: "#{message.chat.username}@gmail.com")
      bot.api.send_message(chat_id: message.chat.id, 
      text: "Welcome @#{message.chat.username} your account has been created and saved in our database")
      displayMessage(message)
    else  
      user = User.find_by(telegram_id: message.chat.id)
    end

    case user.step
    when 'add'
      user.events.create(description: message.text)
      user.step = 'date'
      user.save
      bot.api.send_message(chat_id: message.chat.id, text: "Enter event date with the following format MM/DD/YYYY")
    when 'date'
      new_event = user.events.last
      new_event.date = message.text
      new_event.save
      user.step = nil
      user.save
      bot.api.send_message(chat_id: message.chat.id, text: "Your event have been successfully created!")
      displayMessage(message)
    when 'deleted'
      if user.events.map{ |event| event.description}.include?(message.text)
        Event.find_by(description: message.text).destroy
        bot.api.send_message(chat_id: message.chat.id, text: "Event deleted successfully")
        displayMessage(message)
      else 
        bot.api.send_message(chat_id: message.chat.id, text: "selected event not in the database")
      end
      user.step = nil
      user.save
      remove_keyboard(message)
    when 'view_events'

    end

    case message.text
    when '/add'
      user.step = 'add'
      user.save
      remove_keyboard(message)
      bot.api.send_message(chat_id: message.chat.id, text: "Enter your event description")
    when '/view_events'
      if Event.all.length > 0
        bot.api.send_message(chat_id: message.chat.id, text: "--------------------------------")
        bot.api.send_message(chat_id: message.chat.id, text: "below are the list of events")
        bot.api.send_message(chat_id: message.chat.id, text: "--------------------------------")
        
        arr = []
        Event.all.each do |event|
          bot.api.send_message(chat_id: message.chat.id, text: "#{event.description}")
          bot.api.send_message(chat_id: message.chat.id, text: "#{event.date}")
          bot.api.send_message(chat_id: message.chat.id, text: "_________________________")
          event_and_date = "EVENT DESCRIPTION:  #{event.description}  " + "  EVENT DATE:  #{event.date}"
          arr << event_and_date
        end
        display_event_as_key(message, arr)
        displayMessage(message)
        user.step = nil
        user.save
        message.text = nil
      else 
        bot.api.send_message(chat_id: message.chat.id, text: "No event to view")
      end
    when '/delete'
      if Event.all.length 0 >
      remove_keyboard(message)
        user.step = 'deleted'
        user.save
        current_user_events = user.events.map{|event| event.description }
        markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: current_user_events)
        bot.api.send_message(chat_id: message.chat.id, text: "select event to delete ", reply_markup: markup)
        message.text = nil
      end
    when '/notify'
      if Event.all.length > 0
        get_notify(message)
        displayMessage(message)
        remove_keyboard(message)
        message.text = nil
        bot.api.send_message(chat_id: message.chat.id, text: "Enter '/cancel_notification' to cancel all notifications")
      end
    when '/cancel_notification'
      scheduler.shutdown if scheduler
      bot.api.send_message(chat_id: message.chat.id, text: "Notification canceled")
      displayMessage(message)
    end
  end
end