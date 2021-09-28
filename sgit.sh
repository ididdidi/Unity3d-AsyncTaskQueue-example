#!/bin/bash

# This script is designed to simplify switching between branches
# To work with a script from the git bash console, you need 
# to file `.bash_aliases`, add a string to the user's directory: 
# ```bash
# alias sgit='./sgit.sh $*'

# Protection against accidental push changes
notPush=(master test)

reset=$(tput sgr 0)
blue=$(tput sgr 1)
green=$(tput setf 2)
cyan=$(tput setf 3)
red=$(tput setf 4)
purple=$(tput setf 5)
yellow=$(tput setf 6)
toend=$(tput hpa $(tput cols))$(tput cub 6)

function Help {
echo "		Commands used with the script:
 add [<fileName>]                        - Add to the index 
 cbr [<branchName> | -b <newBranchName>] - Checkout to the branch 
 cmt [ -a(add) -m <comment>]             - Create a new commit
 mrg [<branchName>]                      - Merge contents of branches
 pll                                     - Get changes from the server
 psh                                     - Send changes to the server
 sts                                     - Show status of files
 hst                                     - To show the tree of commits
 rst                                     - Hard reset to HEAD"
}

function Add {
	if git add $@
		then
			local branchName=$(git symbolic-ref --short HEAD)
			echo "${green}Add in to index files in ${yellow}$(pwd)${reset} on ${cyan}($branchName)${reset}${toend}${green}[OK]${reset}"
		else
			echo "${red}Command ${reset}[git add $@]${red} failed with error: $?${reset}${toend}${red}[fail]${reset}"
			return 1
		fi
}

function AddToIndex {
	shift
	args=$@
	if [ $# -eq 0 ]
	then
		args+=" ."
	fi
	Add $args
}

function Checkout {
	if git checkout $@
	then
		branchName=${@//*[[:punct:]]*/}
		echo "${green}Checkout branch in ${yellow}$(pwd)${reset} on ${cyan}($branchName)${reset}${toend}${green}[OK]${reset}"
	else
		echo "${red}Command ${reset}[git checkout $@]${red} failed with error: $?${reset}${toend}${red}[fail]${reset}"
		return 2
	fi
}

function CreateNewBranch {
	local newBranchName=${@//*[[:punct:]]*/}
	if ([ -n "$newBranchName" ])
	then
		while true
		do
			echo -n "${yellow}Create a new branch ${cyan}($newBranchName)${yellow}? (Y/n)${reset}"
			read item
			if ([ -z "$item" ] || [ "$item" == 'y' ] || [ "$item" == 'Y' ])
			then
				Checkout -b $newBranchName
				#git push --set-upstream origin $(git symbolic-ref --short HEAD)
				break
			elif ([ "$item" == 'n' ] || [ "$item" == 'N' ])
			then
				echo "${yellow}The new branch ${cyan}($newBranchName)${yellow} will not be created.${reset}"
				break
			fi
		done
	else
		return 3
	fi
}

function CheckAndChangeBranch {
	str=$(git branch)
	branchs=($str)
	if [[ ! " ${branchs[@]} " =~ " ${@} " || "$@" =~ "-b" ]]
	then
		CreateNewBranch $@
	elif Checkout $@
	then
		return
	else
		return 4
	fi
}

function ChangeBranch {
	shift
	if [ -z "$@" ]
	then
		git branch
		return 0
	fi
	if CheckAndChangeBranch $@
	then
		echo
	else
		return 5
	fi
	git diff origin
}

function CheckUntrackedFiles {
	local untracked=$(git ls-files -o --exclude-standard -z | xargs -0)
	if ([ -n "$untracked" ])
	then
		echo "In subproject has untracked files: ${red}$untracked${reset}"
		while true
		do
			echo -n "${yellow}Add untracked files to index? (Y/n)${reset}"
			read item
			if ([ -z "$item" ] || [ "$item" == 'y' ] || [ "$item" == 'Y' ])
			then
				if Add .
				then
					echo 	
				else
					return 6
				fi
				break
			elif ([ "$item" == 'n' ] || [ "$item" == 'N' ])
			then
				break
			fi
		done
	fi
}

function Commit {

	CheckUntrackedFiles
	
	local cached=$(git diff --cached)
	if ([ -n "$cached" ])
	then	
		if git commit "$@"
		then
			local branchName=$(git symbolic-ref --short HEAD)
			echo "${green}Created new commit in ${yellow}$(pwd) ${reset}on ${cyan}($branchName)${reset}${toend}${green}[OK]${reset}"
		else
			echo "Commit was not created in ${yellow}$(pwd)${reset}"
			echo "${red}Command ${yellow}[git commit $@]${red} failed! Error: $? ${toend}${red}[fail]${reset}"
		fi
	else
		echo "${red}No indexed changes in ${yellow}$(pwd)${reset}"
	fi
	
	local diff=$(git diff)
	if ([ -n "$diff" ])
	then
		git status
	fi
}

function CreateCommit {
	shift
	
	if (([[ "$1" == "-"*"m"* ]] && [ -n $2 ]) || ([[ "$2" == "-"*"m"* ]] && [ -n $3 ]))
	then
		local args+=$@
	else
		while true
		do
			echo -n "${yellow}Add comment ${reset}"
			read comment
			if ([ -n "$comment" ])
			then
				args+="-m $comment"
				break
			fi
		done
	fi
	
	Commit "$args"
}

function Status {
	local branchName=$(git symbolic-ref --short HEAD)
	echo "${green}Status project in ${yellow}$(pwd) ${reset}on ${cyan}($branchName)${reset}"
	git status $@
}

function GetStatus {
	Status
}

function Merge {
	shift
	git merge $@
}

function Push {
	local branchName=$(git symbolic-ref --short HEAD)
	if git push -u origin $branchName
	then
		echo "${green}Push commit ${purple}[$(git rev-parse --short HEAD)] ${green}in ${yellow}$(pwd) ${reset}on ${cyan}($branchName)${reset}${toend}${green}[OK]${reset}"
	else
		echo "${red}Failed to push changes ${yellow}[$args]${red} with error: $? ${toend}${red}[fail]${reset}"
		return 8
	fi
}

function PushChanges {
	local branchName=$(git symbolic-ref --short HEAD)
	if [[ " ${notPush[@]} " =~ " ${branchName} " ]]
	then
		echo "${red}The branch ${cyan}($branchName)${red} is not intended for push changes!${reset}" 
		echo "Make a push changes from another branch and create a pull request."
		return 9
	fi
	
	Push
}

function HardReset {
	git reset --hard HEAD
	git clean -fdx
}

function GetCommitsHistory {
	git log --pretty=format:"%h %s" --graph
}

#BIGIN
case "$1" in
	add) AddToIndex $@;;
	cbr) ChangeBranch $@;;
	cmt) CreateCommit $@;;
	sts) GetStatus $@;;
	mrg) Merge $@;;
	pll) PullChanges $@;;
	psh) PushChanges ;;
	hst) GetCommitsHistory ;;
	rst) HardReset ;;
	help) Help ;;
	*) echo "${yellow} $1 ${red}- is not an option${reset}" ; Help ;;
esac
#END