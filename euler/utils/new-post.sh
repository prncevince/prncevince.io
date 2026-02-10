#! /usr/bin/env sh

HELP=$(cat <<'EOF'
Template script to create new Project Euler problem directory file structure.
Ran via `euler/utils/new-post.sh # "problem title"` or `make euler-new-post P=# N="problem title"`
P: problem number as an integer
N: problem title name - quoted
EOF
)

usage() {
  echo "Usage: new-post.sh -P <problem integer> -N <quoted problem title> [-h for help]"
}

while getopts ":NP:h" opt; do
  case $opt in
	P)
  	P="$OPTARG"
    break
  	;;
	N)
  	N="$OPTARG"
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

if [ -n "$P" ]; then
  Rscript euler/utils/new-post.R "$P" "$N"
  exit 0
fi

# if no options are set - run help message
echo "$HELP"
usage
exit 0