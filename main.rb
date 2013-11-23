require 'rubygems'
require 'sinatra'
  
set :sessions, true

helpers do
  def calculate_total(cards)
    face_value = cards.map {|card| card[1]}
      
      total = 0
      face_value.each do |val|
        if val == "A"
          total += 11
        else
          total += (val.to_i == 0 ? 10 : val.to_i)
        end
      end
      
      face_value.select{|val| val == 'A'}.count.times do
        break if total <= 21
        total -= 10
      end
    total
  end

  def card_image(card)
    suit =case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J','Q','K','A'].include?(card[1])
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end
  
  "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner(msg)
    @success = "<strong>#{session[:player_name]} win! </strong> #{msg}"
    @play_again = true
    @show_button = false
    @show_dealer_button = false
    session[:player_pot] = session[:player_pot] + session[:player_bet]

  end

  def lose(msg)
    @error = "<strong>#{session[:player_name]} lose! </strong> #{msg}"
    @play_again = true
    @show_button = false
    @show_dealer_button = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    if session[:player_pot] == 0
      @play_again = false
      @error = "Sorry, You lose all money,click new game!"
    end
  end

  def tie(msg)
    @success = "<strong>Sorry, it's a tie! </strong> #{msg}"
    @play_again = true
    @show_button = false
    @show_dealer_button = false
  end
end


before do
  @show_button = true
end

get '/' do 
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  session[:player_pot] = 500
  erb :new_player
end 

post '/new_player'do
  if params[:player_name] == ''
    @error = "Name is required!"
    halt erb(:new_player)
  end
  session[:player_name]=params[:player_name]
  redirect '/bet'
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet  
end

post '/bet' do
  bet_single = params[:bet_amount].to_i
  if bet_single == 0 || bet_single.nil?
    @error = "Sorry, you must enter a number"
    halt erb(:bet)
  elsif bet_single > session[:player_pot]
    @error = "Sorry, you don't have enough money!"
    halt erb(:bet)
  elsif session[:player_pot] - params[:bet_amount].to_i == 0
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/betall'
  else session[:player_bet] = params[:bet_amount].to_i
    @success = "You bet $#{bet_single}"
  end
  redirect '/game'
end

get '/betall' do
  erb :betall
end

get '/game' do
session[:turn] = session[:player_name]

suit = ['H','D','S','C']
value = ['2','3','4','5','6','7','8','9','J','Q','K','A']
session[:deck] = suit.product(value).shuffle!


session[:player]=[]
session[:dealer]=[]
session[:player] << session[:deck].pop
session[:player] << session[:deck].pop
session[:dealer] << session[:deck].pop
session[:dealer] << session[:deck].pop

erb :game
end

post '/game/player/hit' do
  session[:player] << session[:deck].pop

  player_total = calculate_total(session[:player])
  if player_total > 21
    lose("sorry, You busted at #{player_total}, Dealer win!")
  elsif calculate_total(session[:player]) == 21
    winner("Congratulations, You hit the Blackjack")
  end

  erb :game
end

post '/game/player/stay' do
  @success = "You chose to stay"
  @show_button = false
  redirect '/game/dealer'
end


get '/game/dealer' do
  session[:turn] = "dealer"
  @show_button = false
  dealer_total = calculate_total(session[:dealer])
  
    if dealer_total == 21
      lose("Sorry, Dealer hit Blackjack")
    elsif dealer_total > 21
      winner("Congratulations Dealer Busted at #{dealer_total}, You win")
    elsif dealer_total >= 17
      redirect '/game/compare'
    else
      @show_dealer_button = true 
    end
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_button = false
  @show_dealer_button = false
  player_total = calculate_total(session[:player])
  dealer_total = calculate_total(session[:dealer])

  if player_total > dealer_total
    winner("#{session[:player_name]} has #{player_total}, dealer has #{dealer_total}")
  elsif player_total < dealer_total
    lose("#{session[:player_name]} has #{player_total}, dealer has #{dealer_total}")
  else
    tie("Both #{session[:player_name]} and dealer stay at #{player_total}")
  end
  
  erb :game
end
  
get '/over' do
  erb :over
end








