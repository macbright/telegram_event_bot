require File.expand_path('../config/environment', __dir__)

require 'telegram/bot'

TOKEN = '1173859008:AAH4z5gonpnQSnoL5OQvEcWcp1ROD05cYOs'

Telegram::Bot::Client.run(TOKEN) do |bot|

  bot.listen do |message|
    if !User.exists?(telegram_id: message.from.id)
      user = User.create(telegram_id: message.chat.id, name: message.from.first_name)
    else  
      user = User.find_by(telegram_id: message.chat.id)
    end

    case user.step
    when 'add'
      user.events.create(description: message.text)
      user.step = 'description'
      user.save
      bot.api.send_message(chat_id: message.chat.id, text: "Enter your event description")
    when 'description'
      new_event = user.events.last
      new_event.description = message.text
      new_event.save
      user.step = 'date'
      user.save
       bot.api.send_message(chat_id: message.chat.id, text: "Enter your event date")
    when 'date'
      new_event = user.events.last
      new_event.date = message.text
      new_event.save
      user.step = nil
      user.save
    when 'delete'
     

    end

    case message.text
    when '/add'
      user.step = 'add'
      user.save
      bot.api.send_message(chat_id: message.chat.id, text: "add your event")
    when '/show'
      user.step = 'show'
      user.save
      bot.api.send_message(chat_id: message.chat.id, text: "view your event")
    when '/delete'
      user.step = 'delete'
      user.save
      current_user_events = user.events.map{|event| event.description }
      markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: current_user_events)
      bot.api.send_message(chat_id: message.chat.id, text: "select event to delete ", 
      reply_markup: markup)
    end
  end
end