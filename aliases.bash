# Interactive Bash helpers for local Docker Compose projects.
case $- in
  *i*) ;;
  *) return ;;
esac

alias dckcmp='docker compose'
alias dk-logs='dckcmp logs -t -f --since 10m'
alias dk-down='dckcmp down'
alias dk-down-up-logs='t=`date +%s` && dckcmp down --remove-orphans && dckcmp up -d && dckcmp logs -t -f --since $t'
alias dk-up-logs='t=`date +%s` && dckcmp up -d && dckcmp logs -t -f --since $t'
alias dk-rst-logs='t=`date +%s` && dckcmp restart && dckcmp logs -t -f --since $t'

dk_shell() {
  local output id name choice idx target
  local -a ids=() names=()
  output=$(docker compose ps -q) || return
  while IFS= read -r id; do
    [ -n "$id" ] && ids+=("$id")
  done <<< "$output"
  local count=${#ids[@]}

  if [ "$count" -eq 0 ]; then
    echo "Error: no running containers found in this directory."
    return 1
  elif [ "$count" -eq 1 ]; then
    target=${ids[0]}
  else
    echo "Multiple containers found. Choose one to connect to:"
    for id in "${ids[@]}"; do
      name=$(docker inspect --format '{{.Name}}' "$id") || return
      names+=("${name#/}")
    done
    for idx in "${!names[@]}"; do
      printf '%s) %s\n' "$((idx + 1))" "${names[$idx]}"
    done
    IFS= read -r -p "Enter the number: " choice || return 1
    if [[ ! "$choice" =~ ^[0-9]+$ ]]; then
      echo "Invalid choice."
      return 1
    fi
    while [ "${#choice}" -gt 1 ] && [[ "$choice" == 0* ]]; do
      choice=${choice#0}
    done
    if [ "${#choice}" -gt "${#count}" ] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$count" ]; then
      echo "Invalid choice."
      return 1
    fi
    idx=$((choice - 1))
    target=${ids[$idx]}
  fi

  docker exec -it "$target" /bin/sh -c 'if [ -x /bin/bash ]; then exec /bin/bash; else exec /bin/sh; fi'
}
alias dk-shell=dk_shell
alias dk-upgrade='dckcmp pull && dckcmp build --pull && dk-down-up-logs ; echo ; echo Remember to run \# docker system prune -a ; echo'
