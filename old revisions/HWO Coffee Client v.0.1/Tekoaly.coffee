############################################################################
# Copyright (C) 2012 Ville Kangas, Tommi Laakso                            #
#                                                                          #
# Licensed under the Apache License, Version 2.0 (the "License");          #
# you may not use this file except in compliance with the License.         #
# You may obtain a copy of the License at                                  #
#                                                                          #
#    http://www.apache.org/licenses/LICENSE-2.0                            #
#                                                                          #
# Unless required by applicable law or agreed to in writing, software      #
# distributed under the License is distributed on an "AS IS" BASIS,        #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #
# See the License for the specific language governing permissions and      # 
# limitations under the License.                                           #
############################################################################

class Tekoaly
	# Viimeisin hetki, kun huikattu serverille omat liike-ehdotukset
	@lastTime = 0

	# Viimeisin tiedossa ollut mailan liikkumissuunta ja nopeus
	@lastDirection = 0
	
	# GameInfo olio, joka sisältää kaiken tarvitun datan kentästä ja pallosta
	@gameInfo =
		level:
			top: 0
			bottom: 480
			left: 0
			right: 640
		ifConfigured: 0
		ballVectorX: 0
		ballVectorY: 0
		ballVelocityInPaddleBounce: 0
		previousTime: 0
		previousBallX: 0
		previousBallY: 0

	# AjatteleSeuraavaLiike funktio, joka laskee minne maila kannattaisi seuraavaksi liikuttaa.
	# 	- Funktio ottaa sisälleen Message viestin, jossa on tarvitut tiedot kentästä ym.
	AjatteleSeuraavaLiike: (message) ->
		meno = 0
		
		# Alustetaan gameInfon tiedot, jos niitä ei ole aiemmin alustettu tai jos ne on muutettu
		if @gameInfo.level.ifConfigured == 0
            @gameInfo.level.top = message.data.conf.ballRadius
            @gameInfo.level.bottom = message.data.conf.maxHeight - message.data.conf.ballRadius
            @gameInfo.level.left = message.data.conf.ballRadius
            @gameInfo.level.right = message.data.conf.maxWidth - (message.data.conf.ballRadius + message.data.conf.paddleWidth)
            @gameInfo.level.ifConfigured = 1
		
		# Lasketaan pallon arvioitu liikkumanopeus ja suunta
		@CalculateBallVector message.data.time, message.data.ball.pos.x, message.data.ball.pos.y

		# Arvioidaan pallon osumakorkeus
		hunchY = @hunchBallEndLocation 3
		hunchY -= (message.data.conf.paddleHeight / 2)
		
		# Tarkistetaan kuinka lähellä mailan keskikohtaa arvioitu osumakohta on
		lahellaHunchia = @kuinkaLahella hunchY, message.data.left.y
		
		# Tarkistetaan onko tarvetta liikkua ylös vaiko alaspäin
		meno = @think hunchY, message.data.left.y
		
		# Määritetään liikkumisnopeus pallon arvioidun osumiskohdan ja mailan keskipisteen avulla
		if lahellaHunchia < 30
			if meno < 0
				meno = -0.5
			else 
				meno = 0.5

		if lahellaHunchia < 10
			if meno < 0
				meno = -0.2
			else 
				meno = 0.2

		if lahellaHunchia < 5
			if meno < 0
				meno = -0.1
			else 
				meno = 0.1

		if lahellaHunchia < 2
			meno = 0.0
			
		# Lasketaan kesto edellisen viestin lähettämisestä serverille
		killekalle = message.data.time - @lastTime
		
		# Jos edellinen viesti lähetetty yli 100ms sitten, voidaan lähettää uusi
		if killekalle > 100
			move =
				msgType: "changeDir"
				data: meno
			@respond move, socket
			@lastTime = message.data.time
			@lastDirection = meno

	# Peli ohi, merkitään nopeus mahdottoman suureksi. :P
	PeliOhi: ->
		@lastDirection = 3;
			
	# Miettii mailan liikkumissuunnan
	think: (pall, mina) ->
		if pall < mina
			-1
		else 
			1

	# Lasketaan kuinka paljon on pallon keskipisteen ja mailan keskipisteen korkeusero
	kuinkaLahella: (pall, mina) ->
		if pall < mina
			mina - pall
		else
			pall - mina
			
	# Lasketaan pallon suunta ja nopeus
	CalculateBallVector: (time, ballX, ballY) ->
		# Paljonko on aikaa kulunut edellisestä sijaintitarkistuksesta
		timeSpan = time - @gameInfo.previousTime
		# Kuinka pitkän matkan pallo on ehtinyt liikkua X ja Y akseleilla
		moveX = ballX - @gameInfo.previousBallX
		moveY = ballY - @gameInfo.previousBallY

		# Lasketaan montako yksikköä per ticksi pallo liikkuu X ja Y akseleilla
		@gameInfo.ballVectorX = moveX / timeSpan
		@gameInfo.ballVectorY = moveY / timeSpan  

		# Merkitään aiemmat uudet arvot vanhoiksi verrokkiarvoiksi
		@gameInfo.previousTime = time
		@gameInfo.previousBallX = ballX
		@gameInfo.previousBallY = ballY
	
	hunchBallEndLocation: (temp) ->
		# initial hunch is center of level:
		hunch = @gameInfo.level.bottom / 2

		if lasttime == 0
			return hunch

		if @gameInfo.ballVectorX > 500 or @gameInfo.ballVectorY > 500
			return hunch

		if @gameInfo.ballVectorX < -500 or @gameInfo.ballVectorY < -500
			return hunch


		# lets play forward for temp ball and see where it goes:
		tempBallX = @gameInfo.previousBallX
		tempBallY = @gameInfo.previousBallY
		tempBallVectorX = @gameInfo.ballVectorX
		tempBallVectorY = @gameInfo.ballVectorY

		if tempBallVectorX == 0
			tempBallVectorX = -1

		# lets make failsafe
		failStick = 1

		# loop until we are at skin of our own paddle:
		while tempBallX > gameInfo.level.left
			tempBallX += tempBallVectorX
			tempBallY += tempBallVectorY

			failStick++     

			# at the level borders:
			if tempBallY > gameInfo.level.bottom or tempBallY < gameInfo.level.top
				tempBallVectorY = -tempBallVectorY
				tempBallY += tempBallVectorY

			# at the enemy gates:
			if tempBallX > gameInfo.level.right
				tempBallVectorX = -tempBallVectorX
				# tempBallVectorX += -0.4
				tempBallX += tempBallVectorX

			if failStick > 40000
				return hunch

		# loop is over, returning the hunch:
		hunch = tempBallY