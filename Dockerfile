FROM ubuntu:18.04

RUN apt-get update

# Install Android SDK
## Dependencies
RUN  apt-get install -y curl ca-certificates openjdk-8-jdk unzip
ENV JAVA8_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV JAVA_HOME $JAVA8_HOME
ENV ANDROID_HOME /opt/android-sdk-linux
ARG ANDROID_SDK_VERSION=4333796
ENV ANDROID_SDK_ZIP http://dl.google.com/android/repository/sdk-tools-linux-$ANDROID_SDK_VERSION.zip

RUN mkdir -p $ANDROID_HOME \
    && curl -L $ANDROID_SDK_ZIP --output sdk.zip \
    && unzip sdk.zip -d $ANDROID_HOME \
    && rm sdk.zip

ENV PATH $PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools
## SDK
### sdkmanager will throw up warnings if this file does not exist
### TODO find out what this is needed for
RUN mkdir -p /root/.android && touch /root/.android/repositories.cfg
### Use verbose flags to keep an eye on progress - some commands take a very long
### time, and without the verbose flag it's impossible to tell if it's hung or
### still working
RUN yes | sdkmanager --verbose 'platform-tools'
RUN yes | sdkmanager --verbose 'emulator'
RUN yes | sdkmanager --verbose 'extras;android;m2repository'
RUN yes | sdkmanager --verbose 'extras;google;google_play_services'
RUN yes | sdkmanager --verbose 'extras;google;m2repository'
RUN yes | sdkmanager --verbose 'build-tools;28.0.3'
RUN yes | sdkmanager --verbose 'platforms;android-28'
RUN yes | sdkmanager --verbose 'add-ons;addon-google_apis-google-23'
RUN yes | sdkmanager --verbose 'system-images;android-19;google_apis;armeabi-v7a'

RUN yes | sdkmanager --update --verbose
RUN yes | sdkmanager --licenses
# Done installing Android SDK

# Set up React Native
## Install node, yarn, and react-native-cli
RUN apt-get install -y nodejs npm \
    && npm i -g yarn \
    && yarn global add react-native-cli npx

### This is the port that the React Native app will use to communicate with the
### build server for loading new builds, and also where the debugger page will
### be hosted (ie. localhost:8081/debugger-ui)
EXPOSE 8081

## Install watchman - required for React Native to build native code, and for
## hot code reloading
RUN apt-get install -y git libssl-dev autoconf automake libtool python-dev \
  pkg-config
RUN git clone https://github.com/facebook/watchman.git \
&& cd watchman \
&& git checkout v4.9.0 \
&& ./autogen.sh \
&& ./configure \
&& make \
&& make install \
&& cd .. \
&& rm -rf watchman
# Done setting up react-native

RUN mkdir /entry
COPY ./entrypoint.sh /entry/

ENV APP_MOUNT /app
# Done setting up non-root user

WORKDIR $APP_MOUNT
ENV GRADLE_USER_HOME $APP_MOUNT/android/gradle_deps

ENTRYPOINT [ "/entry/entrypoint.sh" ]