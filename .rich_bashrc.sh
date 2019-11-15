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
else
	echo "Not sure which other commands can be used for non-interactive terminal."
fi

git config --global user.name "rijobro"
git config --global user.email "richard.brown@ucl.ac.uk"


######################################################
#                   LINUX
######################################################
if [ "$(uname)" != "Darwin" ] && [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	alias open='xdg-open'
	# Save github password for an hour
	git config --global credential.helper cache
	git config --global credential.helper 'cache --timeout=3600'
fi

######################################################
#                   Notifications
######################################################

function RB_disp_notification {
	if [[ "$(uname)" == "Darwin" ]]; then
		$(osascript -e "display notification \"$2\" with title \"$1\"")
	elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
		zenity --notification --text="${1}: ${2}"
	fi
}
if [[ "$shell" == "bash" ]]; then
	export -f RB_disp_notification
fi

function RB_make {
	make "$@"
	result=$?
	if [[ $result -eq 0 ]];
	then
		RB_disp_notification "Build complete" "Success!"
	elif [[ ! $result -eq 130 ]];
	then
		RB_disp_notification "Build complete" "Failed!"
	fi
} 
if [[ "$shell" == "bash" ]]; then
	export -f RB_make
fi