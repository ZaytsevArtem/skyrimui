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

	//fabd: subtle button text highlight with mouse and keyboard focus
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
	}

	function setupButtons(): Void
	{
		if (undefined != ButtonContainer) {
			ButtonContainer.removeMovieClip();
			ButtonContainer = undefined;
		}

		MessageButtons = [];

		//fabd: no longer used, see below
		//var controllerOrConsole: Boolean = arguments[0];

		if (arguments.length > 1) {
			ButtonContainer = createEmptyMovieClip("Buttons", getNextHighestDepth());
			var buttonXOffset: Number = 0;

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

				//fabd: a wee bit darker to emphasize the highlight
				buttonText._alpha = MessageBox.SELECTION_ROLLOUT_ALPHA;

				buttonText.SetText(arguments[i], true);

				//fabd: resize the HitArea MC so that it fits the button text.
				// The hit area width includes the selection indicator (helps with short labels like 'Ok').
				button.HitArea._width = buttonText._width + MessageBox.SELECTION_INDICATOR_WIDTH;
				button.HitArea._height = buttonText._height + /*MessageBox.MESSAGE_TO_BUTTON_SPACER*/ 9 * 2; // 9 most closely matches vanilla
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
		
			//fabd: always enable the gamepad style navigation
			//if (controllerOrConsole) {
				Selection.setFocus(MessageButtons[0]);
			//}
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

		//fabd: move the highlight with the keyboard focus
		for (var i:Number = 0; i < MessageButtons.length; i++) {
			var isFocused:Boolean = MessageButtons[i] === aEvent.target;
			MessageButtons[i].ButtonText._alpha = isFocused ? MessageBox.SELECTION_ROLLOVER_ALPHA : MessageBox.SELECTION_ROLLOUT_ALPHA;
		}

		//fabd: cycle from here if pressing TAB
		lastTabIndex = Number(aEvent.target._name.substr(-1));
	}

	//fabd: adds subtle highlight, and mouseover sets focus to avoid seeing two SelectionIndicator at once
	function RollOverCallback(aEvent: Object): Void
	{
		//GlobalFunc.getInstance().Deebug("RollOverCallback() type = " + aEvent.type + " thisname " + this._name);

		var b:Button = Button(this);
		b.ButtonText._alpha = aEvent.type == "rollOver" ?  MessageBox.SELECTION_ROLLOVER_ALPHA : MessageBox.SELECTION_ROLLOUT_ALPHA;

		if (aEvent.type === "rollOver") {
			Selection.setFocus(this);
		}
	}

	function onKeyDown(): Void
	{
		var iKeyCode: Number = Key.getCode();
		
		//GlobalFunc.getInstance().Deebug("Pressed key code " + iKeyCode + " Ascii " + Key.getAscii() + " char " + String.fromCharCode(iKeyCode));

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

	//fabd: cycle to the next "Exit" like button if present
	function focusExitOrBackButtonIfPresent()
	{
		var aExitLabels: Array = ['Return', 'Back', 'Exit', 'Cancel', 'No'];
		var b: Number, i:Number, j: Number;

		for (i = 1; i <= MessageButtons.length; i++) {
			// cycle between buttons, so wraparound
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

	//fabd: returns the index of a button which has an "Exit" meaning, or -1 (may enable later with SKSE)
	/*
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
	*/

	function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		//GlobalFunc.getInstance().Deebug("handleInput() for " + details.code + " v " + details.value + " idx " + details.controllerIdx);

		if (GlobalFunc.IsKeyPressed(details)) {
			if (details.navEquivalent == NavigationCode.TAB) {
				focusExitOrBackButtonIfPresent();
				return true;
			}
			
			//fabd: TAB and ESCAPE can't be distinguished :( (may be enabled later with SKSE)
			/*
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
