require File.expand_path('../config/environment', __dir__)

require 'telegram/bot'

TOKEN = '1173859008:AAH4z5gonpnQSnoL5OQvEcWcp1ROD05cYOs'

def displayMessage(message)
  Telegram::Bot::Client.run(TOKEN) do |bot|
    bot.api.send_message(chat_id: message.chat.id, text: "Type '/add' to add an event ")
    bot.api.send_message(chat_id: message.chat.id, text: "Type '/view_events' to view all events ")
    bot.api.send_message(chat_id: message.chat.id, text: "Type '/delete' to delete event created by you")
    bot.api.send_message(chat_id: message.chat.id, text: "Type '/notify' to get notify of an upcoming event ")
  end
end


Telegram::Bot::Client.run(TOKEN) do |bot|

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
    when 'view_events'

    end

    case message.text
    when '/add'
      user.step = 'add'
      user.save
      bot.api.send_message(chat_id: message.chat.id, text: "Enter your event description")
      
    when '/view_events'
      bot.api.send_message(chat_id: message.chat.id, text: "--------------------------------")
      bot.api.send_message(chat_id: message.chat.id, text: "below are the list of events")
      bot.api.send_message(chat_id: message.chat.id, text: "--------------------------------")
      Event.all.each do |event|
        bot.api.send_message(chat_id: message.chat.id, text: "#{event.description}")
        bot.api.send_message(chat_id: message.chat.id, text: "#{event.date}")
        bot.api.send_message(chat_id: message.chat.id, text: "_________________________")
      end
      displayMessage(message)
      user.step = nil
      user.save
    when '/delete'
      user.step = 'deleted'
      user.save
      current_user_events = user.events.map{|event| event.description }
      markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: current_user_events)
      bot.api.send_message(chat_id: message.chat.id, text: "select event to delete ", reply_markup: markup)
    when '/notify'
      bot.api.send_message(chat_id: message.chat.id, text: "*********************************")
      bot.api.send_message(chat_id: message.chat.id, 
      text: "Hello #{message.chat.username} below are the list of upcoming Events. Plan to attend ")
      bot.api.send_message(chat_id: message.chat.id, text: "**********************************")
      Event.all.each do |event|
        p Event.upcoming_event(event)
        if Event.upcoming_event(event) 
          bot.api.send_message(chat_id: message.chat.id, text: "#{event.description}")
          bot.api.send_message(chat_id: message.chat.id, text: "#{event.date}")
          bot.api.send_message(chat_id: message.chat.id, text: "----------------------------")
        end
      end
    end
  end
end