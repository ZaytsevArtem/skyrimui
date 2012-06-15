﻿import gfx.events.EventDispatcher;
import gfx.ui.InputDetails;
import gfx.ui.NavigationCode;
import gfx.managers.FocusHandler;
import Shared.GlobalFunc;

class Shared.CenteredList extends MovieClip
{
	var BottomHalf: MovieClip;
	var EntriesA: Array;
	var SelectedEntry: MovieClip;
	var TopHalf: MovieClip;
	var bMultilineList: Boolean;
	var bRepositionEntries: Boolean;
	var bToFitList: Boolean;
	var dispatchEvent: Function;
	var fCenterY: Number;
	var iMaxEntriesBottomHalf: Number;
	var iMaxEntriesTopHalf: Number;
	var iSelectedIndex: Number;

	function CenteredList()
	{
		super();
		EntriesA = new Array();
		EventDispatcher.initialize(this);
		Mouse.addListener(this);
		iSelectedIndex = 0;
		fCenterY = SelectedEntry._y + SelectedEntry._height / 2;
		bRepositionEntries = true;
		
		iMaxEntriesTopHalf = 0;
		while (TopHalf["Entry" + iMaxEntriesTopHalf] != undefined) {
			++iMaxEntriesTopHalf;
		}
		
		iMaxEntriesBottomHalf = 0;
		while (BottomHalf["Entry" + iMaxEntriesTopHalf] != undefined) {
			++iMaxEntriesBottomHalf;
		}
	}

	function ClearList()
	{
		EntriesA.splice(0, EntriesA.length);
	}

	function handleInput(details: InputDetails, pathToFocus: Array): Boolean
	{
		var bHandledInput: Boolean = false;
		if (GlobalFunc.IsKeyPressed(details)) {
			if (details.navEquivalent == NavigationCode.UP) {
				moveListDown();
				bHandledInput = true;
			}
			else if (details.navEquivalent == NavigationCode.DOWN) 
			{
				moveListUp();
				bHandledInput = true;
			}
			else if (details.navEquivalent == NavigationCode.ENTER && iSelectedIndex != -1) 
			{
				dispatchEvent({type: "itemPress", index: iSelectedIndex, entry: EntriesA[iSelectedIndex]});
				bHandledInput = true;
			}
		}
		return bHandledInput;
	}

	function onMouseWheel(delta)
	{
		for (var item: Object = Mouse.getTopMostEntity(); item && item != undefined && FocusHandler.instance.getFocus(0) == this; item = item._parent) {
			if (item == this) 
			{
				if (delta < 0) {
					moveListUp();
				} else if (delta > 0) {
					moveListDown();
				}
			}
		}
	}

	function onPress(aiMouseIndex, aiKeyboardOrMouse)
	{
		
		for (var item: Object = Mouse.getTopMostEntity(); item && item != undefined; item = item._parent) {
			if (item == SelectedEntry) 
			{
				dispatchEvent({type: "itemPress", index: iSelectedIndex, entry: EntriesA[iSelectedIndex], keyboardOrMouse: aiKeyboardOrMouse});
			}
		}
	}

	function onPressAux(aiMouseIndex, aiKeyboardOrMouse, aiButtonIndex)
	{
		if (aiButtonIndex == 1) 
		{
			for (var item: Object = Mouse.getTopMostEntity(); item && item != undefined; item = item._parent) {
				if (item == SelectedEntry) 
				{
					dispatchEvent({type: "itemPressAux", index: iSelectedIndex, entry: EntriesA[iSelectedIndex], keyboardOrMouse: aiKeyboardOrMouse});
				}
			}
		}
	}

	function get selectedTextString()
	{
		return EntriesA[iSelectedIndex].text;
	}

	function get selectedIndex()
	{
		return iSelectedIndex;
	}

	function set selectedIndex(aiNewIndex)
	{
		iSelectedIndex = aiNewIndex;
	}

	function get selectedEntry()
	{
		return EntriesA[iSelectedIndex];
	}

	function get entryList()
	{
		return EntriesA;
	}

	function set entryList(anewArray)
	{
		EntriesA = anewArray;
	}

	function moveListUp()
	{
		if (iSelectedIndex < EntriesA.length - 1) 
		{
			++iSelectedIndex;
			UpdateList();
			dispatchEvent({type: "listMovedUp"});
		}
	}

	function moveListDown()
	{
		if (iSelectedIndex > 0) 
		{
			--iSelectedIndex;
			UpdateList();
			dispatchEvent({type: "listMovedDown"});
		}
	}

	function UpdateList()
	{
		iSelectedIndex = Math.min(Math.max(iSelectedIndex, 0), EntriesA.length - 1);
		if (iSelectedIndex > 0) 
		{
			UpdateTopHalf(EntriesA.slice(0, iSelectedIndex));
		}
		else 
		{
			UpdateTopHalf();
		}
		SetEntry(SelectedEntry, EntriesA[iSelectedIndex]);
		if (iSelectedIndex < EntriesA.length - 1) 
		{
			UpdateBottomHalf(EntriesA.slice(iSelectedIndex + 1));
		}
		else 
		{
			UpdateBottomHalf();
		}
		RepositionEntries();
	}

	function UpdateTopHalf(aEntryArray)
	{
		for (var i: Number =  iMaxEntriesTopHalf - 1; i > 0; i--) 
		{
			var iEntryIndex: Number = i - (iMaxEntriesTopHalf - aEntryArray.length);
			if (iEntryIndex >= 0 && iEntryIndex < aEntryArray.length) 
			{
				SetEntry(TopHalf["Entry" + i], aEntryArray[iEntryIndex]);
			}
			else 
			{
				SetEntry(TopHalf["Entry" + i]);
			}
		}
	}

	function UpdateBottomHalf(aTextArray)
	{
		for (var i: Number = 0; i < iMaxEntriesBottomHalf; i++) 
		{
			if (i < aTextArray.length) 
			{
				SetEntry(BottomHalf["Entry" + i], aTextArray[i]);
			}
			else 
			{
				SetEntry(BottomHalf["Entry" + i]);
			}
		}
	}

	function SetEntry(aEntryClip, aEntryObject)
	{
		if (bMultilineList == true) 
		{
			aEntryClip.textField.verticalAutoSize = "top";
		}
		if (bToFitList == true) 
		{
			aEntryClip.textField.textAutoSize = "shrink";
		}
		if (aEntryObject.text != undefined) 
		{
			if (aEntryObject.count > 1) 
			{
				aEntryClip.textField.SetText(aEntryObject.text + " (" + aEntryObject.count + ")");
			}
			else 
			{
				aEntryClip.textField.SetText(aEntryObject.text);
			}
			return;
		}
		aEntryClip.textField.SetText(" ");
	}

	function SetupMultilineList()
	{
		bMultilineList = true;
		
		for (var i: Number = 0; i < iMaxEntriesTopHalf; i++) {
			TopHalf["Entry" + i].textField.verticalAutoSize = "top";
		}

		for (var i: Number = 0; i < iMaxEntriesBottomHalf; i++) {
			BottomHalf["Entry" + i].textField.verticalAutoSize = "top";
		}
		
		if (SelectedEntry != undefined) 
		{
			SelectedEntry.textField.verticalAutoSize = "top";
		}
	}

	function SetupToFitList()
	{
		bToFitList = true;
		var __reg2 = 0;
		for (var i: Number = 0; i < iMaxEntriesTopHalf; i++) {
			TopHalf["Entry" + i].textField.verticalAutoSize = "shrink";
		}

		for (var i: Number = 0; i < iMaxEntriesBottomHalf; i++) {
			BottomHalf["Entry" + i].textField.verticalAutoSize = "shrink";
		}
		if (SelectedEntry != undefined) 
		{
			SelectedEntry.textField.textAutoSize = "shrink";
		}
	}

	function RepositionEntries()
	{
		if (bRepositionEntries) {		
			var iyPosition = 0;
			for (var i: Number = 0; i < iMaxEntriesTopHalf; i++) {
				TopHalf["Entry" + i]._y = iyPosition;
				iyPosition += TopHalf["Entry" + i]._height;
			}
			
			iyPosition = 0;
			for (var i: Number = 0; i < iMaxEntriesBottomHalf; i++) {
				BottomHalf["Entry" + i]._y = iyPosition;
				iyPosition += BottomHalf["Entry" + i]._height;
			}
			
			SelectedEntry._y = fCenterY - SelectedEntry._height / 2;
			TopHalf._y = SelectedEntry._y - TopHalf._height;
			BottomHalf._y = SelectedEntry._y + SelectedEntry._height;
		}
	}
}
