#! /usr/bin/env sh

HELP=$(cat <<'EOF'
Template script to create new Project Euler problem directory file structure.
Ran via `euler/utils/new-post.sh P=#` or `make euler-new-post P=#`
# where P is the problem number as an integer
EOF
)

usage() {
  echo "Usage: new-post.sh -P <problem integer> [-h for help]"
}

while getopts ":P:h" opt; do
  case $opt in
	P)
  	echo "$OPTARG"
    exit 0
  	;;
	h)
  	echo "$HELP"
    usage
    exit 0
  	;;
  :)
    echo "Error: Option -$OPTARG requires an argument."
    usage
    exit 1
    ;;
  \?)
    echo "Error: Invalid option -$OPTARG"
    usage
    exit 1
    ;;
  esac
done

# if no options are set - run help message
echo "$HELP"
usage
exit 0