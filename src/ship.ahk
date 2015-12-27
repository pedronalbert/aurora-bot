class Ship {
	static healPercent :=
	static shieldPercent :=
	static percentPerBar := 4.761904761904762
	static healBarsColor := 0x7FD878
	static healBarsShader := 15
	static shieldBarsColor := 0xD8D378
	static shieldBarsShader := 20
	static statsBoxCors := {}
	static lastCollectCors := [0,0]

	init() {
		if (this.setStatsBoxCors()) {
			return true
		} else {
			return false
		}
	}

	setStatsBoxCors() {
		ImageSearch, x, y, Client.boxCors.x1, Client.boxCors.y1, Client.boxCors.x2, Client.boxCors.y2, *10 ./img/ship_stats_box.bmp

		If (ErrorLevel = 0) {
			this.statsBoxCors.x1 := x
			this.statsBoxCors.y1 := y
			this.statsBoxCors.x2 := x + 190
			this.statsBoxCors.y2 := y + 105

			return true
		} else {
			MsgBox, % "ERRROR! the ship stats are not visible, set to visible or re-configure the client coors"
			return false
		}
	}

	getHealPercent() {
		this.healPercent := 0

		healBarsCorsX := this.statsBoxCors.x1 + 27
		healBarsCorsY := this.statsBoxCors.y1 + 46

		Loop, 21 {
			healBarsCorsX := healBarsCorsX + 3
			PixelSearch, x, y, healBarsCorsX, healBarsCorsY, healBarsCorsX, healBarsCorsY, % this.healBarsColor, % this.healBarsShader, Fast

			if ErrorLevel = 0
				this.healPercent += this.percentPerBar
		}
		OutputDebug, % "Ship heal: " this.healPercent
		return this.healPercent

	}

	getShieldPercent() {
		this.shieldPercent := 0
		shieldBarsCorsX := this.statsBoxCors.x1 + 27
		shieldBarsCorsY := this.statsBoxCors.y1 + 63

		Loop, 21 {
			shieldBarsCorsX := shieldBarsCorsX + 3

			PixelSearch, x, y, shieldBarsCorsX, shieldBarsCorsY, shieldBarsCorsX, shieldBarsCorsY, % this.shieldBarsColor, % this.shieldBarsShader, Fast

			if ErrorLevel = 0
				this.shieldPercent += this.percentPerBar
		}
		OutputDebug, % "Ship shield: " this.shieldPercent
		return this.shieldPercent
	}

	isMoving() {
		x := Minimap.boxCors.x1 + 114
		y := Minimap.boxCors.y1 + 37

		PixelGetColor, color, x, y

		if (color = "0xFFFFFF") {
		    OutputDebug, % "Ship is moving"
			return true
		} else {
		    OutputDebug, % "Ship is stopped"
			return false
		}
	}

	isDead() {
		ImageSearch, corsX, corsY, Client.boxCors.x1, Client.boxCors.y1, Client.boxCors.x2, Client.boxCors.y2, *10 ./img/repair_button.bmp

		if (ErrorLevel = 0) {
			OutputDebug, % "Ship is dead"
			return true
		} else {
		    OutputDebug, % "Ship is alive"
			return false
		}
	}

	approach(cors) {
		centerX := Client.boxCors.x2 / 2
		centerY := Client.boxCors.y2 / 2

		corsX := (centerX + cors[1]) / 2 ;midle point
		corsY := (centerY + cors[2]) / 2 ;middle point

		if(corsX > centerX) {
			diff := corsX - centerX

			if(diff < 170) {
				corsX := centerX + 170
			}
		} else {
			diff := centerX - corsX

			if(diff < 170) {
				corsX := centerX - 170
			}
		}
		OutputDebug, % "Ship approach to: " corsX " , " corsY
		MouseClick, Left, corsX, corsY, 1, 0
	}

	collect(cors) {
		lastCollectX := this.lastCollectCors[1]
		lastCollectY := this.lastCollectCors[2]

		if ( (cors[1] >= (lastCollectX - 5)) and (cors[1] <= (lastCollectX + 5)) and (cors[2] >= (lastCollectY - 5)) and (cors[2] <= (lastCollectY + 5))) {
				this.goAway()
		} else {
			this.lastCollectCors := cors
			OutputDebug, % "Ship collect: " cors[1] " , " cors[2]
			MouseClick, Left, cors[1] + 3, cors[2] + 3, 1, 0
		}
	}

	goAway() {
		OutputDebug,% "Ship goAway"
		Minimap.move()
		Sleep, 3000
	}

	/*
	 * Revive the ship
	 * @param {string} mode - BASE | PORTAL
	 * @return {string} mode used
	*/
	revive(mode := "BASE") {
		MouseMove, 0, 0 , 0 ;move mouse away

		if (mode = "BASE") {
			image := "repair_base"
		} else if (mode = "PORTAL") {
			image := "repair_portal"
		}

		ImageSearch, corsX, corsY, Client.boxCors.x1, Client.boxCors.y1, Client.boxCors.x2, Client.boxCors.y2, % "*10 ./img/" image ".bmp"

		if (ErrorLevel = 0) {

			MouseClick, Left, corsX + 5, corsY + 5, 1, 15 ;click on mode

			Sleep, 1000

			ImageSearch, corsX, corsY, Client.boxCors.x1, Client.boxCors.y1, Client.boxCors.x2, Client.boxCors.y2, *10 ./img/repair_button.bmp

			if (ErrorLevel = 0) {
				Random, variationX, 5, 100
				Random, variationY, 5, 20

				MouseClick, Left, corsX + variationX, corsY + variationY, 1, 15 ;click on repair button

				Sleep, 8000

				if (this.isDead()) {
					Client.reloadClient()
				}
				else {
					OutputDebug, % "Ship revived on " mode
					return mode
				}
			}

		} else {
			this.revive("BASE")
			OutputDebug, % "Ship revived on BASE"
			return "BASE"
		}
	}

	isInvisible(invisibleCpu) {
		cloackCors := Client.getCloackCors(invisibleCpu)

		corsX := cloackCors[1]
		corsY := cloackCors[2]

		if (cloackCors) {
			PixelGetColor, color, corsX - 2, corsY + 2

			if (color = "0x846B29") {
				OutputDebug, % "Ship is invisible"
				return false
			} else {
				OutputDebug, % "Ship is not invisible"
				return true
			}
		} else {
			return true
		}
	}

	setInvisible(invisibleCpu)  {
		cloackCors := Client.getCloackCors(invisibleCpu)

		if (isObject(cloackCors)) {
			OutputDebug, % "Ship set invisible"
			MouseClick, Left,  % cloackCors[1] + 5, % cloackCors[2] + 5, 1, 5
		}
	}

	changeConfig() {
		OutputDebug, % "Ship change config"
		Send {c}
	}

}