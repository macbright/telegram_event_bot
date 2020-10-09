require File.expand_path('../config/environment', __dir__)

require 'telegram/bot'

TOKEN = '1173859008:AAH4z5gonpnQSnoL5OQvEcWcp1ROD05cYOs'

Telegram::Bot::Client.run(TOKEN) do |bot|

  bot.listen do |message|
    p message
  end
end