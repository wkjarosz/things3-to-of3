----------------------------------------------------
----------------------------------------------------
-- Import selected projects from Things to OmniFocus
----------------------------------------------------
----------------------------------------------------
--
-- Adapted from https://gist.github.com/matellis/69954d4212b1a36c13aad3de4e75187e by wkjarosz
-- Script taken from: http://forums.omnigroup.com/showthread.php?t=14846&page=2 && https://gist.github.com/cdzombak/11265615 
-- 
-- Import just the selected projects in Things 3 to Omnifocus 3
--
-- Title of project for stuff in things with no project (avoids going into the Inbox)
--
property noProjectTitle : "No Project In Things"


tell application "Things3"
	
	--
	-- Import Projects into OF3
	-- 
	set projectList to {{missing value, noProjectTitle, "", "active", "", {}}}
	set completedProjectList to {}
	set AppleScript's text item delimiters to ","
	set theProjects to selected to dos
	repeat with aProject in theProjects
		if class of aProject is project then
			log name of aProject as string
			log status of aProject as string
			set areaName to null
			if area of aProject is missing value then
				set areaName to missing value
			else
				set areaName to name of area of aProject as string
			end if
			set projectName to name of aProject as string
			set projectNotes to notes of aProject as string
			--		set tagList to every text item of (tag names of aProject as string)
			set tagList to my gatherTagsOf(aProject)
			
			set projectCompletionDate to completion date of aProject
			
			-- status: active/?on hold/?done/?dropped. vs open completed canceled
			set projectStatus to status of aProject as string
			
			copy {areaName, projectName, projectNotes, projectStatus, projectCompletionDate, tagList} to end of projectList
		end if
	end repeat
	
	log "Processing " & (count of projectList) & " projects"
	
	tell application "OmniFocus"
		tell default document
			repeat with aProject in projectList
				set theFolderName to first item in aProject
				set theProjectName to second item in aProject
				set theProjectNotes to third item in aProject
				set theProjectStatus to fourth item in aProject
				set theProjectTags to sixth item in aProject
				set theProjectCompletionDate to fifth item in aProject
				
				if theFolderName is missing value then
					-- no area
					if (project theProjectName exists) then
						set theProject to project theProjectName
					else
						set theProject to make new project with properties {name:theProjectName, note:theProjectNotes}
					end if
					
					if theProjectStatus is "completed" then
						if not (my isItemInList(completedProjectList, theProject)) then
							copy {theProject, theProjectCompletionDate} to end of completedProjectList
						end if
					end if
				else
					-- Project inside an area
					tell folder theFolderName
						if project theProjectName exists then
							set theProject to project theProjectName
						else
							-- add tags
							set theProject to make new project with properties {name:theProjectName, note:theProjectNotes}
						end if
						
						if theProjectStatus is "completed" then
							if not (my isItemInList(completedProjectList, theProject)) then
								copy {theProject, theProjectCompletionDate} to end of completedProjectList
							end if
						end if
						
					end tell
					move theProject to (end of sections of (first folder whose name is theFolderName))
				end if
				
				-- Write out tags
				my writeTagsTo(theProject, theProjectTags)
			end repeat
		end tell
	end tell
	
	-- Mark complete any projects that should be that way
	tell application "OmniFocus"
		tell default document
			repeat with completedProjectInfo in completedProjectList
				set completedProject to first item of completedProjectInfo
				set completedProjectDate to second item of completedProjectInfo
				mark complete completedProject
				set completion date of completedProject to completedProjectDate
			end repeat
		end tell
	end tell
end tell -- Things application

-- Clumsy way of seeing if an item is in the Inbox as Things doesn't expose a "list" property
on isItemInList(theList, theItem)
	set the matchFlag to false
	repeat with anItem from 1 to the count of theList
		if theList contains anItem then Â
			set the matchFlag to true
	end repeat
	return the matchFlag
end isItemInList
-- Another hack for heirarchal tags to say "does tag exist inside this other tag?"
on isTagInList(theList, theItem)
	set the matchFlag to false
	repeat with anItem from 1 to the count of theList
		if item anItem of theList is theItem then Â
			set the matchFlag to true
	end repeat
	return the matchFlag
end isTagInList
-- less clumsy inbox hack
on isInInbox(anItem)
	return ((area of anItem is missing value) and (project of anItem is missing value))
end isInInbox
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
