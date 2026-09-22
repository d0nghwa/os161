# Dockerfile by Robert Marmorstein (marmorsteinrm@longwood.edu), Longwood University
# Feel free to use under the public domain

FROM debian/eol:bullseye

ARG OLD_SECURITY_URL="http://deb.debian.org/debian-security"
ARG NEW_SECURITY_URL="http://snapshot.debian.org/archive/debian-security/20260824T000000Z"

RUN sed -i "s|$OLD_SECURITY_URL|$NEW_SECURITY_URL|g" /etc/apt/sources.list \
    && apt-get update

# Install compiler and essential libraries for building os161
RUN apt-get -y install build-essential libgmp10 libmpfr6 libmpc3 libgmp-dev libmpfr-dev libmpc-dev file libncurses5-dev wget

# Install tools for students to use
RUN apt-get -y install vim git emacs

# Prepare os161 structure ($HOME is /root)
# RUN mkdir $HOME/os161 && mkdir $HOME/os161/toolbuild && mkdir $HOME/os161/tools && mkdir $HOME/os161/tools/bin
RUN mkdir $HOME/tools && mkdir $HOME/tools/os161 && mkdir $HOME/tools/os161/bin
RUN mkdir $HOME/tools/sys161 && mkdir $HOME/tools/sys161/bin

ENV SYS161="sys161-2.0.3"
ENV BINUTILS161="binutils-2.24+os161-2.1"
ENV GCC161="gcc-4.8.3+os161-2.1"
ENV GDB161="gdb-7.8+os161-2.1"
ENV MIRROR="http://people.ece.ubc.ca/os161/download"

# Must use gnu89 and c++11 for older tools to compile without multiple definition errors.  -fcommon might be enough, instead.
ENV CFLAGS="-std=gnu89 -fcommon"
ENV CXXFLAGS="-std=c++11"

RUN echo '*** Downloading OS/161 toolchain ***'
RUN wget $MIRROR/$BINUTILS161.tar.gz
RUN wget $MIRROR/$GCC161.tar.gz
RUN wget $MIRROR/$GDB161.tar.gz
RUN wget $MIRROR/$SYS161.tar.gz

RUN echo '*** Unpacking OS/161 toolchain ***'
RUN for file in *.tar.gz; do tar -xzf $file; rm -f $file; done

ENV PRE_CC=$CC
ENV PRE_CFLAGS=$CFLAGS
ENV CC=gcc
ENV CFLAGS="-std=gnu89 -fcommon"
ENV CXXFLAGS="-std=c++11"


RUN echo '*** Building binutils ***'
WORKDIR $BINUTILS161
RUN ls
RUN ls intl
RUN find . -name '*.info' | xargs touch
RUN touch intl/plural.c
RUN ./configure --nfp --disable-werror --target=mips-harvard-os161 --prefix=$HOME/tools/os161 2>&1 | tee ../binutils.log
RUN make 2>&1 | tee -a ../binutils.log
RUN make install 2>&1 | tee -a ../binutils.log
WORKDIR ..
RUN echo '*** Finished building binutils ***'
RUN rm -rf $BINUTILS161

RUN echo '*** Building gcc ***'
RUN PATH=$HOME/tools/sys161/bin:$HOME/tools/os161/bin:$PATH
RUN export PATH
WORKDIR $GCC161
RUN find . -name '*.info' | xargs touch
RUN touch intl/plural.c
RUN mkdir ../gcc-build
WORKDIR ../gcc-build
RUN ../$GCC161/configure --enable-languages=c,lto -nfp --disable-shared --disable-threads --disable-libmudflap --disable-libssp --disable-libstdcxx --disable-nls --target=mips-harvard-os161 --prefix=$HOME/tools/os161 2>&1 | tee ../gcc.log
RUN make 2>&1 | tee -a ../gcc.log
RUN make install 2>&1 | tee -a ../gcc.log
WORKDIR ..
RUN echo '*** Finished building gcc ***'
RUN rm -rf $GCC161
RUN rm -rf gcc-build

RUN echo '*** Building gdb ***'
WORKDIR $GDB161
RUN find . -name '*.info' | xargs touch
RUN touch intl/plural.c
RUN ./configure --target=mips-harvard-os161 --prefix=$HOME/tools/os161 --disable-werror 2>&1 | tee ../gdb.log
RUN make 2>&1 | tee -a ../gdb.log
RUN make install 2>&1 | tee -a ../gdb.log
WORKDIR ..
RUN echo '*** Finished building gdb ***'
RUN rm -rf $GDB161

RUN echo '*** Building System/161 ***'
WORKDIR $SYS161
RUN ./configure --prefix=$HOME/tools/sys161 mipseb 2>&1 | tee ../sys161.log
RUN make 2>&1 | tee -a ../sys161.log
RUN make install 2>&1 | tee -a ../sys161.log
WORKDIR ..
RUN mv $SYS161 sys161
RUN echo '*** Finished building System/161 ***'

WORKDIR os161/bin
COPY rename_files.sh .
RUN chmod +x rename_files.sh
RUN ./rename_files.sh
#RUN bash -c 'for file in *; do ln -s "$file" "${file:13}"; done'
#RUN for file in *; do ln -s $file ${file:13}; done
WORKDIR ../..

WORKDIR ~
RUN echo 'PATH=$HOME/tools/sys161/bin:$HOME/tools/os161/bin:$PATH' >> $HOME/.bashrc
RUN echo 'set path = ($path $HOME/tools/os161/bin $HOME/tools/sys161/bin)' >> $HOME/.cshrc

# Build bmake
RUN mkdir /scratch
WORKDIR /scratch
RUN wget http://www.os161.org/download/bmake-20101215.tar.gz
RUN wget http://www.os161.org/download/mk-20100612.tar.gz
RUN tar -xzf bmake-20101215.tar.gz
WORKDIR /scratch/bmake/
RUN tar -xvf ../mk-20100612.tar.gz

RUN ./configure --prefix=$HOME/tools/os161 --with-default-sys-path=$HOME/tools/os161/share/mk
RUN sh ./make-bootstrap.sh
RUN mkdir -p  $HOME/tools/os161/share/man/man1 $HOME/tools/os161/share/mk
RUN cp bmake $HOME/tools/os161/bin
RUN cp bmake.1 $HOME/tools/os161/share/man/man1
RUN sh mk/install-mk $HOME/tools/os161/share/mk

RUN rm -rf /scratch

ENV CC=$PRE_CC
ENV CFLAGS=$PRE_CFLAGS
RUN echo '*** Done ***'

