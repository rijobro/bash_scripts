if [ -n "$ZSH_VERSION" ]; then
	shell=zsh
elif [ -n "$BASH_VERSION" ]; then
	shell=bash
else
	echo "Not sure what type of terminal we're in!"
fi

# HISTORY OPTIONS
HISTFILESIZE=1000000000
HISTSIZE=1000000000
# When the shell exits, append to the history file instead of overwriting it
if [[ "$shell" == "zsh" ]]; then
	HISTFILE=~/.zsh_history     #Where to save history to disk
	SAVEHIST=$HISTSIZE          #Number of history entries to save to disk
	HISTDUP=erase               #Erase duplicates in the history file
	setopt    appendhistory     #Append history to the history file (no overwriting)
	setopt    sharehistory      #Share history across terminals
	setopt    incappendhistory  #Immediately append to the history file, not just when a term is killed
elif [[ "$shell" == "bash" ]]; then
	# After each command, append to the history file and reread it
	HISTCONTROL=ignoredups:erasedups # Avoid duplicates
	PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"
	# add timestamp
	export HISTTIMEFORMAT="%F %T "
fi

# If interactive
if [ ! -z "$PS1" ]; then
	# Allows for searching after entering part of command
	if [[ "$shell" == "zsh" ]]; then
		autoload -U up-line-or-beginning-search
		autoload -U down-line-or-beginning-search
		zle -N up-line-or-beginning-search
		zle -N down-line-or-beginning-search
		bindkey "^[[A" up-line-or-beginning-search # Up
		bindkey "^[[B" down-line-or-beginning-search # Down
	elif [[ "$shell" == "bash" ]]; then
		bind '"[A":history-search-backward'
		bind '"[B":history-search-forward'
	fi
fi

alias del='mv "$@" ~/.Trash'

######################################################
#                   LINUX AND GIT
######################################################
if [ "$(uname)" != "Darwin" ] && [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	alias open='xdg-open'
	# Save github password for an hour
	git config --global credential.helper cache
	git config --global credential.helper 'cache --timeout=3600'
fi
git config --global pager.branch false
git config --global user.name "Richard Brown"
git config --global user.email "33289025+rijobro@users.noreply.github.com"
# Delete all remote git branches - useful for when forking and only want master
function git_del_remote_branches {
	if [ "$#" -ne 1 ]; then
		echo "Error: $0 github username as argument"
		return 1
	fi
	uname=$1
	git branch -r | grep $uname | while read -r line ; do git push $uname --delete ${line#"${uname}/"}; done
}
if [[ "$shell" == "bash" ]]; then
	export -f git_del_remote_branches
fi

######################################################
#                   Notifications
######################################################
# Display a notification. Or if on linux and there's a file ~/.tmp/notifications.log
# the put the results in there, as this implies it's an SSH server and the results
# are being watched so that the message can be printed locally (see RB_watch_ssh).
function RB_disp_notification {
	if [ "$#" -ne 2 ]; then
		echo "Error: $0 expects 2 arguments"
		return 1
	fi
	if [[ "$(uname)" == "Darwin" ]]; then
		$(osascript -e "display notification \"$2\" with title \"$1\"")
	elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
		zenity --notification --text="${1}: ${2}" > /dev/null 2>&1
		if [ -f ~/.tmp/notifications.log ]; then
			echo "${1}: ${2}" >> ~/.tmp/notifications.log
		fi
	fi
}
if [[ "$shell" == "bash" ]]; then
	export -f RB_disp_notification
fi

function RB_ {
	if [ "$#" -eq 0 ]; then
		echo "Error: $0 expects at least 1 argument."
		return 1
	fi
	command="$@"
	"$@"
	result=$?
	if [[ $result -eq 0 ]]; then
		RB_disp_notification "Task complete: Success!" "$command"
	elif [[ ! $result -eq 130 ]]; then
		RB_disp_notification "Task complete: Failed!" "$command"
	fi
	return $result
}
if [[ "$shell" == "bash" ]]; then
	export -f RB_
fi
# Bind the ctrl+j to use the RB_ function
if [ ! -z "$PS1" ]; then
	if [[ "$shell" == "bash" ]]; then
		bind '"\C-j": "\C-aRB_ \C-m"'
	fi
fi
# For getting ssh notifications
function RB_watch_ssh {
	if [ "$#" -ne 1 ]; then
		echo "Error: $0 expects server (e.g., user@address:port) as argument."
		return 1
	fi
	ssh $1 'mkdir -p ~/.tmp && echo "Watching server notifications" > ~/.tmp/notifications.log && tail -f ~/.tmp/notifications.log' | \
	while read line; do
		RB_disp_notification "$1" "$line"
	done
	RB_disp_notification "$1" "Stopping watch of notifications"
	# if [[ "$(uname)" == "Darwin" ]]; then
	# 	say "Stopping watching $1 for notifications"
	# fi
}
# Connect via SSH and watch for notifications
function RB_ssh {
	if [ "$#" -ne 1 ]; then
		echo "Error: $0 expects server (e.g., user@address:port) as argument."
		return 1
	fi
	RB_watch_ssh $1 </dev/null &
	pid=$(( $! + 1 ))
	trap "kill $pid 2> /dev/null" EXIT
	disown  # need to disown to not get message when killing pid at end
	ssh $1
}
######################################################
#                   Notifications
######################################################

function RB_vnc_ssh () {
	host=$1
	port=${2:-5901}
	localport=$((30000 + RANDOM % 20000))
	ssh -o ExitOnForwardFailure=yes -fNL "${localport}:localhost:$port" "$host" || return 1
	pid=$(lsof -t -i:$localport)
	open -W vnc://localhost:$localport
	kill "$pid"
}

######################################################
#                   Mac Docker
######################################################

if [[ "$(uname)" == "Darwin" ]]; then
	function docker_is_running() {
		command docker system info > /dev/null 2>&1 && echo 0 || echo 1
	}
	function docker() {
		if [[ "$1" == "run" || "$1" == "build" || "$1" == "search" ]]; then
			if [[ "$(docker_is_running)" != "0" ]]; then
				echo -e "\n\nStarting daemon...\n\n"
				open --background -a Docker
				res=$?
				if [ $res -ne 0 ]; then
					return $res
				fi
				while [[ "$(docker_is_running)" != "0" ]]; do
					sleep 1
				done
			fi
		fi
		command docker "${@}"
	}
	function docker_stop() {
		test -z "$(docker ps -q 2>/dev/null)" && osascript -e 'quit app "Docker"'
	}
fi
