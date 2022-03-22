# Building and Installing the gem #

These steps must be tweaked for the location of Cache on your system. Replace anywhere it says `/opt/cache` with this location.

1.  install Cache.
2.  build gem:
    gem build activerecord-intersys-adapter.gemspec
3.  install gem passing Cache install path directive
    gem install --local activerecord-intersys-adapter-X.X.X.gem -- --with-cache-install-path=/opt/cache-2009
4.  ensure Cache libraries are in system's load path:
4a. Linux:
    echo '/opt/cache/dev/cpp/lib/lnxrhx86' > /etc/ld.so.conf.d/cache.conf
4b. OS X:
    echo 'export DYLD_LIBRARY_PATH=/opt/cache/dev/cpp/lib/macx64:$DYLD_LIBRARY_PATH' >> ~/.bash_profile

At this point it should be all good.

If you use Bundler (http://gembundler.com/):
1. Tell it where your Cache installation is by setting a config option. eg -

    bundle config build.activerecord-intersys-adapter --with-cache-install-path=/opt/cache

2. Add following line into Gemfile:
   gem 'activerecord-intersys-adapter', :git => 'git@github.com:RSDi/activerecord-intersys-adapter.git', :branch => 'rails3'
3. Run 'bundle install' to install gem.
