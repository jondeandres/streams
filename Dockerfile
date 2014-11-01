FROM phusion/baseimage

MAINTAINER jondeandres "https://github.com/jondeandres"

# Install packages for building ruby
RUN apt-get update
RUN apt-get install -y --force-yes build-essential wget git
RUN apt-get install -y --force-yes zlib1g-dev libssl-dev libreadline-dev libyaml-dev libxml2-dev libxslt-dev
RUN apt-get clean

RUN wget -P /root/src ftp://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.4.tar.gz
RUN cd /root/src; tar xvf ruby-2.1.4.tar.gz
RUN cd /root/src/ruby-2.1.4; ./configure; make install

RUN gem update --system
RUN gem install bundler

RUN mkdir -p /root/.ssh/
ADD id_rsa /root/.ssh/id_rsa
RUN touch /root/.ssh/known_hosts
RUN ssh-keyscan github.com >> /root/.ssh/known_hosts

RUN a=1 git clone git@github.com:jondeandres/streams /root/streams
RUN cd /root/streams; bundle install

EXPOSE 4567
CMD ["/usr/local/bin/foreman","start","-d","/root/streams"]