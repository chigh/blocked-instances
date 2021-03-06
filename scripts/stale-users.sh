#!/usr/bin/env bash
date=$(date +%Y%m%d)
stale_users="/var/tmp/stale-users-${date}.txt"

_find() {

    sudo -i -u postgres /bin/bash -l -c "psql -A -d mastodon_production \
        -c \"SELECT username||'@'||domain FROM public.accounts WHERE last_webfingered_at < \
        (CURRENT_TIMESTAMP - interval '3 months')\"" | \
        tail -n +2 | head -n -1 | tee ${stale_users}
}

_clean() {
    cd ~/live

    for user in $(cat ${stale_users})
    do
        username=$(echo ${user} | awk -F'@' '{print $1}')
        domain=$(echo ${user} | awk -F'@' '{print $2}')

    set -x
RAILS_ENV=production bundle exec rails r "
begin
    a = Account.find_by(username: \"${username}\", domain: \"${domain}\")
    a.destroy
rescue => err
end"
    set +x
    done
    [[ -f ${stale_users} ]] && rm -i ${stale_users} || true
}

_usage() {
    printf "$(basename $0) [--find|-f] [--clean|-c]\n"
}

case ${1:-} in
    --find|-f) _find ;;
   --clean|-c) _clean ;;
            *) _usage ;;
esac
