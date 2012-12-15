import gfx.io.GameDelegate;
import gfx.controls.Button;
import gfx.ui.NavigationCode;
import gfx.ui.InputDetails;
import Shared.GlobalFunc;
import skse;

class MessageBox extends MovieClip
{
	static var WIDTH_MARGIN: Number = 20;
	static var HEIGHT_MARGIN: Number = 30;
	static var MESSAGE_TO_BUTTON_SPACER: Number = 10;
	static var SELECTION_INDICATOR_WIDTH: Number = 25;

	//fabd: subtle button text highlight with mouse and keyboard focus
	static var SELECTION_ROLLOVER_ALPHA: Number = 100;
	static var SELECTION_ROLLOUT_ALPHA: Number = 80;

	//DirectX Scan Codes returned by SKSE
	static var SKSE_KEY_ESC: Number = 0x01;
	static var SKSE_KEY_TAB: Number = 0x0F;

  /* Stage Elements */
	var MessageText: TextField;
	
	var Divider: MovieClip;
	var Background_mc: MovieClip;
	
  /* Private Variables */
	var ButtonContainer: MovieClip;
	var DefaultTextFormat: TextFormat;
	
	var Message: TextField;
	var MessageButtons: Array;

	// expired6978's menu loader
	var proxyMenu: MovieClip;

	// Better MessageBox Controls
	var MessageBtnLabels: Array;
	var lastTabIndex: Number = -1;
	var setFocusIntervalId: Number = null;
	var exitLabels: Array = [
	  // Button labels recognized by the TAB feature
		'Return', 'Back', 'Exit', 'Cancel', 'No',
		'Done'   // used by "Forgotten Mastery"
	];

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

		//GlobalFunc.getInstance().Deebug("setupButtons() " + arguments.slice(1));

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
			//	Selection.setFocus(MessageButtons[0]);
			//}

			// reset tab index for TAB feature
			lastTabIndex = -1;

			//fabd: temporary solution until I figure why setFocus() doesn't always work
			setFocusIntervalId = setInterval(this, "focusItDammitWhatsWrongWithYou", 50);
		}
	}

	//fabd: note for this workaround fix:
	//      10ms NO! doesn't work
	//      25ms NO! works in most cases but not at Enchanting Table "Ok" confirmation
	//      50ms OK! in all reported cases.
	function focusItDammitWhatsWrongWithYou(): Void
	{
		if (setFocusIntervalId !== null) {
			clearInterval(setFocusIntervalId);
			setFocusIntervalId = null;
		}
		Selection.setFocus(MessageButtons[0]);
	}

	function InitButtons(): Void
	{
		for (var i: Number = 0; i < MessageButtons.length; i++) {
			MessageButtons[i].handlePress = function () {};
			MessageButtons[i].addEventListener("press", this, "ClickCallback");
			MessageButtons[i].addEventListener("focusIn", this, "FocusCallback");
			MessageButtons[i].addEventListener("rollOver", this, "RollOverCallback");
			MessageButtons[i].addEventListener("rollOut", this, "RollOverCallback");
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
	
		// check for custom menu (expired6978) 
		ProcessMessage(aText);
	}

	/**
	 * Menu loader code by expired6978, added for compatibility with upcoming mods.
	 * Example:
	 *   Debug.MessageBox("$$loadMovie=bla.swf$$")
	 */
	function ProcessMessage(aText)
	{
		if(aText.slice(0, 2) == "$$" && aText.slice(aText.length-2, aText.length) == "$$")
		{
			var command: String = aText.slice(2, aText.length-2);
			var key = command.slice(0, command.indexOf("="));
			if (key == undefined)
				return;
				
			var val = command.slice(command.indexOf("=") + 1);
			if (val == undefined)
				return;
				
			if(key.toLowerCase() == "loadmovie")
			{
	      var MessageContainer: MovieClip = _root.MessageMenu;
				MessageContainer._visible = false;
				MessageContainer.enabled = false;
				
				proxyMenu = _root.createEmptyMovieClip(val, _root.getNextHighestDepth());
				proxyMenu.loadMovie(val + ".swf");
			}
		}
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

	// Returns the digit from the button name
	function getButtonId(button: Button): Number
	{
		return Number(button._name.substr(-1))
	}

	function ClickCallback(aEvent: Object): Void
	{
		GameDelegate.call("buttonPress", [getButtonId(aEvent.target)]);
	}

	function FocusCallback(aEvent: Object): Void
	{
		GameDelegate.call("PlaySound", ["UIMenuFocus"]);

		//GlobalFunc.getInstance().Deebug("FocusCallback() " + (aEvent.target ? aEvent.target._name : 'woops'));

		//fabd: move the highlight with the keyboard focus
		for (var i:Number = 0; i < MessageButtons.length; i++) {
			var isFocused:Boolean = MessageButtons[i] === aEvent.target;
			MessageButtons[i].ButtonText._alpha = isFocused ? MessageBox.SELECTION_ROLLOVER_ALPHA : MessageBox.SELECTION_ROLLOUT_ALPHA;

			if (MessageButtons[i] === aEvent.target) {
				// cycle from here if pressing TAB
				lastTabIndex = i;
			}
		}
	}

	//fabd: adds subtle highlight, and mouseover sets focus to avoid seeing two SelectionIndicator at once
	function RollOverCallback(aEvent: Object): Void
	{
		//GlobalFunc.getInstance().Deebug("RollOverCallback() type = " + aEvent.type + " thisname " + this._name);
		var b:Button = Button(aEvent.target);
		b.ButtonText._alpha = aEvent.type == "rollOver" ?  MessageBox.SELECTION_ROLLOVER_ALPHA : MessageBox.SELECTION_ROLLOUT_ALPHA;

		if (aEvent.type === "rollOver") {
			Selection.setFocus(b);
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
	function findNextExitButton(iStartFrom: Number): Number
	{
		var b: Number, i:Number, j: Number;

		if (iStartFrom === undefined) {
			iStartFrom = -1;
		}

		for (i = 1; i <= MessageButtons.length; i++) {
			// cycle between buttons, so wraparound
			b = (iStartFrom + i) % MessageButtons.length;

			if (b === iStartFrom)
				continue;

			for (j = 0; j < exitLabels.length; j++) {
				if (exitLabels[j] === MessageBtnLabels[b]) {
					Selection.setFocus(MessageButtons[b]);
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
		
			var skseKeyDown: Number = skse ? skse.GetLastKeycode(true) : 0;
			//GlobalFunc.getInstance().Deebug("handleInput() SKSE Key: " + skseKeyDown);

			// the ESC key finds and selects the first exit button (needs SKSE to distinguish Tab from Escape)
			if (skseKeyDown === MessageBox.SKSE_KEY_ESC) {
				lastTabIndex = findNextExitButton();
				if (lastTabIndex !== -1) {
					var btnId: Number = getButtonId(MessageButtons[lastTabIndex]);
					GameDelegate.call("buttonPress", [btnId]);
					return true;
				}
			}

			// the TAB key cycles through exit buttons, eg. between "Return" and "Exit"
			if (details.navEquivalent == NavigationCode.TAB) {
				findNextExitButton(lastTabIndex);
				return true;
			}
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
