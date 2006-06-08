property withResolveAlias : true

on run
	local thelist, theItem, nSelect
	set thelist to getSelection()
	set nSelect to length of thelist
	if nSelect is 0 then
		set thelist to missing value
	end if
	return thelist
end run

on resolveAlias(theItem)
	
	tell application "Finder"
		if withResolveAlias and (class of theItem is alias file) then
			try
				set theItem to (original item of theItem)
			end try
		end if
	end tell
	return theItem
end resolveAlias

on getSelection()
	tell application "Finder"
		set selectedList to selection
	end tell
	set thelist to {}
	repeat with theItem in selectedList
		set theItem to resolveAlias(theItem)
		set theItem to theItem as alias -- if without conversion into alias, the path of package is not ends with ":"
		set theItem to theItem as Unicode text
		if theItem does not end with ":" then
			set end of thelist to POSIX path of theItem
		end if
	end repeat
	return thelist
end getSelection
