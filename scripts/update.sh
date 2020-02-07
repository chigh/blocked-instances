. ~/common.sh
set +o errexit

_int_trap

printf "This will update Mastodon (no release candidates), Ruby, and node.js..."


_pause

printf "Mastodon updates...\n"
cd ~/live
#git pull
git fetch origin --tags
git checkout -f $(git tag -l | grep -v 'rc[0-9]*$' | sort -V | tail -n 1)


printf "Press <enter> to update Ruby and node.js dependencies...\n"
_pause

cd ~/.rbenv/plugins/ruby-build && git pull && cd -
rbenv install x.x.x
rbenv global x.x.x

cd ~/live
gem install bundler

cd ~/live
bundle install --deployment --without development test
bundle install -j$(getconf _NPROCESSORS_ONLN) --deployment --without development test

cd ~/live
curl --compressed -o- -L https://yarnpkg.com/install.sh | bash # Upgrade yarn
yarn install --pure-lockfile


printf "Press <enter> to update the database schema...\n"
_pause

cd ~/live
RAILS_ENV=production bundle exec rails db:migrate

printf "Press <enter> to precomile assets...\n"
_pause

cd ~/live
RAILS_ENV=production bundle exec rails assets:precompile

printf "Prese <enter> to run maintenance...\n"
_pause

cd ~/live
RAILS_ENV=production bundle exec rails mastodon:maintenance:remove_regeneration_markers
