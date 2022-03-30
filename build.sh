#!/usr/bin/env bash

set -euxo pipefail

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain none -y
source $HOME/.cargo/env

if [ -v WITH_LATEST_MMTK_CORE ]
then
  git clone https://github.com/mmtk/mmtk-core
  pushd mmtk-core
else
  git clone https://github.com/wks/mmtk-core
  pushd mmtk-core
  git checkout is_arbitrary_address_alloced
fi
export RUSTUP_TOOLCHAIN=$(cat rust-toolchain)
rustup toolchain install $RUSTUP_TOOLCHAIN
rustup target add i686-unknown-linux-gnu --toolchain $RUSTUP_TOOLCHAIN
cargo build
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
