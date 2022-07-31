# things3-to-of3 scripts
Set of scripts I used to import tasks from Things 3 into Omnifocus 3.

This is based on the [gist](https://gist.github.com/matellis/69954d4212b1a36c13aad3de4e75187e) by [matellis](https://github.com/matellis/) by I found that a single automated imported didn't work, so I split the script into three separate scripts.

In particular, I wasn't able to find a way to have the script iterate truly through all projects and tasks in the Logbook (including the Logbook only included the recent items, not the older ones you get by clicking "More items" in the Things 3 iterface). To circumvent this I needed to manually select these logbook items and have the script also consider all selected items. 

## Usage

The semi-automatic workflow that works for me was to first run the `things3-to-of3` script. Then to select all the Logbook entries and run `add-selected-things3-projects-to-of3`. Finally, this unfortunately doesn't import the tasks within the Logbook projects, so you must go through each completed Logbook project, select it's tasks, and run the `add-selected-things3-todos-to-of3` script.

# Caveats

I do not plan to maintain this script going forward, but am releasing it in case it is useful for others to adapt and build off of.