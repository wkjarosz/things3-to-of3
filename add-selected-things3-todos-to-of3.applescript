--------------------------------------------------
--------------------------------------------------
-- Import selected todos from Things to OmniFocus
--------------------------------------------------
--------------------------------------------------
--
-- Adapted from https://gist.github.com/matellis/69954d4212b1a36c13aad3de4e75187e by wkjarosz
-- Script taken from: http://forums.omnigroup.com/showthread.php?t=14846&page=2 && https://gist.github.com/cdzombak/11265615 
-- 
-- Import just the selected todos in Things 3 to Omnifocus 3
--
-- Title of project for stuff in things with no project (avoids going into the Inbox)
--
property noProjectTitle : "No Project In Things"

tell application "Things3"
	
	--
	--  Import T3 To Dos into OF3
	--
	
	-- Combine all the folders you want to search here
	-- Options are: Inbox, Today, Anytime, Upcoming, Someday, Lonely Projects, Logbook, Trash, selected to dos
	set theTodos to selected to dos
	
	-- Go through all the tasks in the combined lists
	log "Processing " & (count of theTodos) & " entries"
	
	repeat with aTodo in theTodos
		-- Get various attributes of Things task
		set theTitle to name of aTodo
		set theNote to notes of aTodo
		set theDueDate to due date of aTodo
		set theStartDate to activation date of aTodo -- aka "Defer Date"
		set theFlagStatus to false
		set theStatus to status of aTodo as string
		set theCompletionDate to completion date of aTodo
		set theCreationDate to creation date of aTodo
		
		-- Get project & area names
		set theFolderName to missing value
		set theProjectNote to ""
		set theProjectName to ""
		set processItemFlag to true
		set isInbox to false
		set isProject to false
		
		if class of aTodo is project then
			-- Is this task actually a project?			
			set isProject to true
		else if ((area of aTodo is missing value) and (project of aTodo is missing value)) then
			-- Is this todo in the Inbox? If so, it needs special treatment
			set isInbox to true
		else if (project of aTodo) is missing value then
			-- Just an orphaned task, no such thing in OF3 so put in a folder
			set theProjectName to noProjectTitle
		else
			-- Regular task inside a project
			set theProjectName to (name of project of aTodo)
			set theProjectNote to (notes of project of aTodo)
			
			-- With a folder
			if area of project of aTodo is missing value then
				set theFolderName to missing value
			else
				set theFolderName to (name of area of project of aTodo)
			end if
		end if
		
		-- Gather tags
		set allTagNames to my gatherTagsOf(aTodo)
		
		-- Create a new task in OmniFocus
		tell application "OmniFocus"
			tell default document
				if not isProject then
					-- Create the actual task - does not de-dupe
					-- Do it differently if inbox
					log theTitle
					-- log theNote
					if isInbox then
						set newTask to make new inbox task with properties {name:theTitle, note:theNote, creation date:theCreationDate, due date:theDueDate, defer date:theStartDate, flagged:theFlagStatus}
					else
						if theFolderName is missing value then
							if project theProjectName exists then
								tell project theProjectName
									set newTask to make new task with properties {name:theTitle, note:theNote, creation date:theCreationDate, due date:theDueDate, defer date:theStartDate, flagged:theFlagStatus}
								end tell
							end if
						else
							tell folder theFolderName
								tell project theProjectName
									set newTask to make new task with properties {name:theTitle, note:theNote, creation date:theCreationDate, due date:theDueDate, defer date:theStartDate, flagged:theFlagStatus}
								end tell
							end tell
						end if
					end if
					
					-- handle completed
					if theStatus is "completed" then
						mark complete newTask
						set completion date of newTask to theCompletionDate
					else if theStatus is "canceled" then
						mark dropped newTask
						set dropped date of newTask to theCompletionDate
					else if theStatus is "open" then
						mark incomplete newTask
						set completion date of newTask to missing value
					end if
					
					-- Process tags
					my writeTagsTo(newTask, allTagNames)
					
				end if -- not a task
			end tell -- OF application
		end tell -- Document
	end repeat -- Things list
end tell -- Things application

-- gather tags
on gatherTagsOf(aTodo)
	set allTagNames to {}
	tell application "Things3"
		repeat with aTag in every tag of aTodo
			if (parent tag of aTag) is missing value then
				copy {null, name of aTag} to end of allTagNames
			else
				copy {name of parent tag of aTag, name of aTag} to end of allTagNames
			end if
		end repeat
	end tell
	return allTagNames
end gatherTagsOf
-- write tags
on writeTagsTo(aTask, tagList)
	tell application "OmniFocus"
		tell default document
			repeat with aTag in tagList
				
				set theParentTag to first item of aTag
				set theChildTag to second item of aTag
				
				if theParentTag is null then
					-- No Parent tag
					add tag theChildTag to tags of aTask
				else
					-- Has a parent tag
					set childTag to (first tag of tag theParentTag whose name is theChildTag)
					add childTag to tags of aTask
				end if
			end repeat -- tags
		end tell
	end tell
end writeTagsTo
