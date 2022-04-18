#!/usr/bin/env bash

set -euxo pipefail

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain none -y
source $HOME/.cargo/env

if [ -v WITH_LATEST_MMTK_CORE ]
then
  git clone https://github.com/mmtk/mmtk-core
  pushd mmtk-core
else
  git clone https://github.com/mmtk/mmtk-core # https://github.com/wks/mmtk-core
  pushd mmtk-configure
  # Currently no difference
fi
export RUSTUP_TOOLCHAIN=nightly # $(cat rust-toolchain)
rustup toolchain install $RUSTUP_TOOLCHAIN
cargo +nightly build
popd

git clone https://github.com/mmtk/mmtk-ruby
pushd mmtk-ruby/mmtk
sed -i 's/^mmtk =/#mmtk =/g' Cargo.toml
cat ../../Cargo.toml.part >> Cargo.toml
cargo build
popd

git clone https://github.com/mmtk/ruby
pushd ruby
if [ -v WITH_UPSTREAM_RUBY ]
then
  git config --global user.email builder@example.com
  git config --global user.name Builder
  git remote add upstream https://github.com/ruby/ruby
  git fetch upstream
  git merge upstream/master
fi
cp ../mmtk-ruby/mmtk/target/debug/libmmtk_ruby.so ./
sudo apt-get install -y autoconf bison
./autogen.sh
./configure --with-mmtk-ruby --prefix=$PWD/build --disable-install-doc
export LD_LIBRARY_PATH=$PWD
export MMTK_PLAN=MarkSweep
export THIRD_PARTY_HEAP_LIMIT=10000000
make
make install
popd
