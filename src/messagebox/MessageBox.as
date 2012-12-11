import gfx.io.GameDelegate;
import gfx.controls.Button;
import gfx.ui.NavigationCode;  //fabd++
import gfx.ui.InputDetails;    //fabd++
import Shared.GlobalFunc;      //fabd++

class MessageBox extends MovieClip
{
	static var WIDTH_MARGIN: Number = 20;
	static var HEIGHT_MARGIN: Number = 30;
	static var MESSAGE_TO_BUTTON_SPACER: Number = 10;
	static var SELECTION_INDICATOR_WIDTH: Number = 25;

	// Subtle button text highlight with mouse and keyboard focus
	static var SELECTION_ROLLOVER_ALPHA: Number = 100;
	static var SELECTION_ROLLOUT_ALPHA: Number = 80;

  /* Stage Elements */
	var MessageText: TextField;
	
	var Divider: MovieClip;
	var Background_mc: MovieClip;
	
  /* Private Variables */
	var ButtonContainer: MovieClip;
	var DefaultTextFormat: TextFormat;
	
	var Message: TextField;
	var MessageButtons: Array;
	var MessageBtnLabels: Array; // holds just the label strings

	//var buttonNumForHotkey:Object = {};
	//var hotkeyPosForButton:Array = [];
	var lastTabIndex: Number = -1;

	function MessageBox()
	{
		super();
		Message = MessageText;
		Message.noTranslate = true;
		MessageButtons = new Array();
		ButtonContainer = undefined;
		DefaultTextFormat = Message.getTextFormat();
		Key.addListener(this);
		GameDelegate.addCallBack("setMessageText", this, "SetMessage");
		GameDelegate.addCallBack("setButtons", this, "setupButtons");

		//fabd++ Scaleform tests
		/*
		var listenerObj = new Object;
		this.onMouseMove = function() {
			 var target = Mouse.getTopMostEntity();
			 //GlobalFunc.getInstance().Deebug("Mouse moved, target = " + target);

			 //GlobalFunc.getInstance().Deebug("Mouse position in _root coords = " + Mouse.getPosition(0));

			 //var mpos:flash.geom.Point = Mouse.getPosition(0);
			 //  GlobalFunc.getInstance().Deebug("translateToScreen mouse coord = " + Stage["translateToScreen"]({x: mpos.x, y:mpos.y}));
		}
		Mouse.addListener(this);
		*/
	}

	/**
	 * This function was meant to select one unique letter hotkey for each
	 * button label. Pressing the associated key would activate the button.
	 *
	 * Abandoned because we can't get the proper keyboard key codes.
	 *
	function setupHotkeyedButtonLabels(aLabels:Array): Array
	{
		var numButtons:Number = aLabels.length;
		var numToSet:Number = numButtons;
		var hotkeyDone:Object = {};
		var buttonDone:Array = [];
		var validHotkeys:String = "abcdefghijklmnopqrstuvwxyz";
		var letterPos:Number = 0;
		var b:Number;

		buttonNumForHotkey = {};

		hotkeyPosForButton.length = 0;
		for (b = 0; b < numButtons; b++)
			hotkeyPosForButton[b] = -1;

		for (letterPos = 0; numToSet && letterPos < 5; letterPos++) {
			for (var b = 0; numToSet && b < numButtons; b++) {
				if (buttonDone[b])
					continue;
				if (letterPos >= aLabels[b].length)
					continue; // label is not long enough for assigning Nth letter

				var c:String = aLabels[b].charAt(letterPos).toLowerCase();
				if (validHotkeys.indexOf(c) >= 0 && !hotkeyDone[c]) {
					hotkeyDone[c] = true;
					buttonDone[b] = true;
					buttonNumForHotkey[c.toUpperCase().charCodeAt(0)] = b;
					hotkeyPosForButton[b] = letterPos;
					numToSet--;

					// highlight the letter
					var s:String = aLabels[b];
					aLabels[b] = (letterPos > 0 ? s.substr(0, letterPos) : '') +
					  '<FONT COLOR="#FFFFFF" ALPHA="#FF">' + s.substr(letterPos, 1) + '</FONT>' + 
						'<FONT COLOR="#E0E0E0">' + s.substr(letterPos + 1) + '</FONT>';
				}
			}
		}

		return aLabels;
	}
	*/

	function setupButtons(): Void
	{
		if (undefined != ButtonContainer) {
			ButtonContainer.removeMovieClip();
			ButtonContainer = undefined;
		}
		MessageButtons.length = 0; // This truncates the array to 0
		var controllerOrConsole: Boolean = arguments[0];

		if (arguments.length > 1) {
			ButtonContainer = createEmptyMovieClip("Buttons", getNextHighestDepth());
			var buttonXOffset: Number = 0;

			//fabd: canceled hotkey idea
			//var btnLabels:Array = setupHotkeyedButtonLabels(arguments.slice(1));

			MessageBtnLabels = [];
			
			for (var i: Number = 1; i < arguments.length; i++) {
				if (arguments[i] == " ")
					continue;
				var buttonIdx: Number = i - 1;
				var button: Button = Button(ButtonContainer.attachMovie("MessageBoxButton", "Button" + buttonIdx, ButtonContainer.getNextHighestDepth()));
				var buttonText: TextField = button.ButtonText;
				buttonText.autoSize = "center";
				buttonText.verticalAlign = "center";
				buttonText.verticalAutoSize = "center";
				buttonText.html = true;

				// fabd: a wee bit darker to emphasize the highlight
				buttonText._alpha = MessageBox.SELECTION_ROLLOUT_ALPHA;

				/*fabd: hotkeys highlighting
				// find out the raw text dimensions
				buttonText.SetText(arguments[i], false);
				// position our little accent
				if (hotkeyPosForButton[buttonIdx] >= 0) {
					var oCharBoundaries: Object = buttonText.getCharBoundaries(hotkeyPosForButton[buttonIdx]);
					button.Accent._x = (0 - buttonText._width) / 2 + oCharBoundaries.left + (oCharBoundaries.width / 2);
					button.Accent._y = oCharBoundaries.bottom;
				} else {
					button.Accent._visible = false;
				}
				// now set the html text
				buttonText.SetText(btnLabels[buttonIdx], true);
				*/
				//fabd: let's adjust the hit area
				buttonText.SetText(arguments[i], true);

				// hit area width include the selection indicator (helps with short lables like 'Ok')
				button.HitArea._width = buttonText._width + MessageBox.SELECTION_INDICATOR_WIDTH;
				button.HitArea._height = buttonText._height + /*MessageBox.MESSAGE_TO_BUTTON_SPACER*/ 9 * 2;
				button.HitArea._x = buttonText._x - MessageBox.SELECTION_INDICATOR_WIDTH / 2;
				button.HitArea._y = buttonText._y - /*MessageBox.MESSAGE_TO_BUTTON_SPACER*/ 9;

				button.SelectionIndicatorHolder.SelectionIndicator._width = buttonText._width + MessageBox.SELECTION_INDICATOR_WIDTH;
				button.SelectionIndicatorHolder.SelectionIndicator._y = buttonText._y + buttonText._height / 2;

				button._x = buttonXOffset + button._width / 2;
				buttonXOffset = buttonXOffset + (button._width + MessageBox.SELECTION_INDICATOR_WIDTH);

				MessageButtons.push(button);
				MessageBtnLabels.push(arguments[i]);
			}
			InitButtons();
			ResetDimensions();
			
			if (1) { //controllerOrConsole) {
				Selection.setFocus(MessageButtons[0]);
			}
		}
	}

	function InitButtons(): Void
	{
		for (var i: Number = 0; i < MessageButtons.length; i++) {
			MessageButtons[i].handlePress = function () {};
			MessageButtons[i].addEventListener("press", ClickCallback);
			MessageButtons[i].addEventListener("focusIn", this, "FocusCallback");
			MessageButtons[i].addEventListener("rollOver", RollOverCallback);
			MessageButtons[i].addEventListener("rollOut", RollOverCallback);
			MessageButtons[i].ButtonText.noTranslate = true;
		}
	}

	function SetMessage(aText: String, abHTML: Boolean): Void
	{
		Message.autoSize = "center";
		Message.setTextFormat(DefaultTextFormat);
		Message.setNewTextFormat(DefaultTextFormat);
		Message.html = abHTML;
		if (abHTML) {
			Message.htmlText = aText;
		} else {
			Message.SetText(aText);
		}
		ResetDimensions();
	}

	function ResetDimensions(): Void
	{
		PositionElements();
		var parentBounds: Object = getBounds(_parent);
		var i: Number = Stage.height * 0.85 - parentBounds.yMax;
		if (i < 0) {
			Message.autoSize = false;
			var extraHeight: Number = i * 100 / _yscale;
			Message._height = Message._height + extraHeight;
			PositionElements();
		}
	}

	function PositionElements(): Void
	{
		var background: MovieClip = Background_mc;
		var maxLineWidth: Number = 0;
		
		for (var i: Number = 0; i < Message.numLines; i++)
			maxLineWidth = Math.max(maxLineWidth, Message.getLineMetrics(i).width);
		
		var buttonContainerWidth = 0;
		var buttonContainerHeight = 0;
		if (ButtonContainer != undefined) {
			buttonContainerWidth = ButtonContainer._width;
			buttonContainerHeight = ButtonContainer._height;
		}
		background._width = Math.max(maxLineWidth + 60, buttonContainerWidth + MessageBox.WIDTH_MARGIN * 2);
		background._height = Message._height + buttonContainerHeight + MessageBox.HEIGHT_MARGIN * 2 + MessageBox.MESSAGE_TO_BUTTON_SPACER;
		Message._y = (0 - background._height) / 2 + MessageBox.HEIGHT_MARGIN;
		ButtonContainer._y = background._height / 2 - MessageBox.HEIGHT_MARGIN - ButtonContainer._height / 2;
		ButtonContainer._x = (0 - ButtonContainer._width) / 2;
		Divider._width = background._width - MessageBox.WIDTH_MARGIN * 2;
		Divider._y = ButtonContainer._y - ButtonContainer._height / 2 - MessageBox.MESSAGE_TO_BUTTON_SPACER / 2;
	}

	function ClickCallback(aEvent: Object): Void
	{
		GameDelegate.call("buttonPress", [Number(aEvent.target._name.substr(-1))]);
	}

	function FocusCallback(aEvent: Object): Void
	{
		GameDelegate.call("PlaySound", ["UIMenuFocus"]);

		//GlobalFunc.getInstance().Deebug("FocusCallback() " + this + " and " + aEvent.target._name);

		// move the highlight with the keyboard focus
		for (var i:Number = 0; i < MessageButtons.length; i++) {
			var isFocused:Boolean = MessageButtons[i] === aEvent.target;
			MessageButtons[i].ButtonText._alpha = isFocused ? MessageBox.SELECTION_ROLLOVER_ALPHA : MessageBox.SELECTION_ROLLOUT_ALPHA;
		}

		// cycle from here if pressing TAB
		lastTabIndex = Number(aEvent.target._name.substr(-1));
	}

	function RollOverCallback(aEvent: Object): Void
	{
		//GlobalFunc.getInstance().Deebug("RollOverCallback() type = " + aEvent.type + " thisname " + this._name);
		var b:Button = Button(this);
		b.ButtonText._alpha = aEvent.type == "rollOver" ?  MessageBox.SELECTION_ROLLOVER_ALPHA : MessageBox.SELECTION_ROLLOUT_ALPHA;
		//var tf:TextFormat = new TextFormat();
		//tf.color = aEvent.type == "rollOver" ? 0xFFFFFF : 0xF2F2F2;
		//b.ButtonText.setTextFormat(tf);

		// mouse cursor changes the focus otherwise we see two selection indicators
		if (aEvent.type === "rollOver") {
			Selection.setFocus(this);
		}
	}

	function onKeyDown(): Void
	{
		var iKeyCode: Number = Key.getCode();
		
		//var b:Number = buttonNumForHotkey[iKeyCode];
		//GlobalFunc.getInstance().Deebug("Pressed key code " + iKeyCode + " Ascii " + Key.getAscii() + " char " + String.fromCharCode(iKeyCode));
		/*fabd: hotkey handling
		if (b != undefined) {
			GlobalFunc.getInstance().Deebug("buttonNumForHotkey button " + b);
			GameDelegate.call("buttonPress", [b]);
			return;
		}*/

		if (iKeyCode == 89 && MessageButtons[0].ButtonText.text == "Yes") {
			GameDelegate.call("buttonPress", [0]);
			return;
		}
		if (iKeyCode == 78 && MessageButtons[1].ButtonText.text == "No") {
			GameDelegate.call("buttonPress", [1]);
			return;
		}
		if (iKeyCode == 65 && MessageButtons[2].ButtonText.text == "Yes to All") {
			GameDelegate.call("buttonPress", [2]);
		}
	}

	// cycle to the next "Exit" like button if present
	function focusExitOrBackButtonIfPresent()
	{
		var aExitLabels: Array = ['Return', 'Back', 'Exit', 'Cancel', 'No'];
		var b: Number, i:Number, j: Number;

		for (i = 1; i <= MessageButtons.length; i++) {
			// cycle between "exit" buttons
			b = (lastTabIndex + i) % MessageButtons.length;

			if (b === lastTabIndex)
				continue;

			for (j = 0; j < aExitLabels.length; j++) {
				if (aExitLabels[j] === MessageBtnLabels[b]) {
					Selection.setFocus(MessageButtons[b]);
					lastTabIndex = b;
					return;
				}
			}
		}
	}

	// returns the index of a button which has a "cancel" meaning, or -1
	function findExitButtonIndex(): Number
	{
		var aCancelLabels: Array = ['Cancel', 'Exit', 'No'];
		var b: Number, j: Number;
		for (b = 0; b < MessageBtnLabels; b++) {
			for (j = 0; j < aCancelLabels.length; j++) {
				if (aCancelLabels[j] === MessageBtnLabels[b]) {
					return b;
				}
			}
		}
		return -1;
	}

	function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
//GlobalFunc.getInstance().Deebug("handleInput() for " + details.code + " v " + details.value + " idx " + details.controllerIdx);
		if (GlobalFunc.IsKeyPressed(details)) {
			if (details.navEquivalent == NavigationCode.TAB) {
				focusExitOrBackButtonIfPresent();
				return true;
			}
			/*fabd: sigh TAB and ESCAPE can't be distinguished
			if (details.navEquivalent == NavigationCode.ESCAPE) {
				var b: Number = findExitButtonIndex();
				if (b !== -1) {
					GameDelegate.call("buttonPress", [b]);
					return true;
				}
				return true;
			}
			*/
		}

		return false;
	}

	function SetPlatform(aiPlatform: Number, abPS3Switch: Boolean): Void
	{
		if (aiPlatform != 0 && MessageButtons.length > 0) {
			Selection.setFocus(MessageButtons[0]);
		}
	}

}
