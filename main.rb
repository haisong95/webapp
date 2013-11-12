require 'rubygems'
require 'sinatra'

set :sessions, true

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
	erb :new_player
end 

post '/new_player'do
  if params[:player_name] == ''
  	@error = "Name is required!"
  	halt erb(:new_player)
  end
	session[:player_name]=params[:player_name]
	redirect '/game'
end

get '/game' do

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
  	

  		if ['J','Q','K','A'].include?(card[1])

      value = case card[1]
	  			when 'J' then 'jack'
	  			when 'Q' then 'queen'
	  			when 'K' then 'king'
	  			when 'A' then 'ace'
  			end
  		else value = card[1].to_s
  		end
  	 

  		"<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end
end
post '/game/player/hit' do
	session[:player] << session[:deck].pop
	  player_total = calculate_total(session[:player])
	if player_total > 21
	  @error = "Sorry, You Busted!"
		@show_button = false
	elsif calculate_total(session[:player]) == 21
		@win = "Congratulations,You win!"
		@show_button = false
	end
	erb :game
end

post '/game/player/stay' do
	@success = "You chose to stay"
	@show_button = false
	redirect '/game/dealer'
end


get '/game/dealer' do
	@show_button = false
	dealer_total = calculate_total(session[:dealer])
  
  if dealer_total == 21
  	@error = "Sorry, Dealer hit Blackjack"
  elsif dealer_total > 21
  	@success = "Congratulations Dealer Busted, You win"
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
  player_total = calculate_total(session[:player])
  dealer_total = calculate_total(session[:dealer])

 	if player_total > dealer_total
 		@success = "You Win!"
 	elsif player_total < dealer_total
 		@success = "Sorry, You lose!"
 	else
 		@error =  "It's a Tie!"
 	end
 	
 	erb :game
 end





  	





