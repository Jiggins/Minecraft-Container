#!/bin/bash

set -eux

export PS4="${0}> "

declare -a JVM_ARGS=(
  -server
  -XX:+UseG1GC
  -XX:+UnlockExperimentalVMOptions
  -Xms8192M
  -Xmn8192M
  -Xmx8192M

  # This tells the RMI layer not to do a full GC every minute. Yeah.
  -Dsun.rmi.dgc.server.gcInterval=2147483646

  # Garbage collection should not take more than 50ms (~1 tick)
  -XX:MaxGCPauseMillis=50

  # This tells G1GC to allocate it's garbage collection blocks in units of
  # 32megs. The reason for this is that chunk data is typically just over 8megs
  # in size, and if you leave it default (16 megs), it'll treat all the chunk
  # data as "humungous" and so it'll have to be garbage collected specially as
  # a result.
  -XX:G1HeapRegionSize=32M

  # Source: https://www.reddit.com/r/feedthebeast/comments/5jhuk9/modded_mc_and_memory_usage_a_history_with_a/?ref=share&ref_source=embed&utm_content=body&utm_medium=post_embed&utm_name=5ef67e55d974422ab2ef735174e65cfc&utm_source=embedly&utm_term=5jhuk9

  # Use 8 parallel threads with two threads for garbage collection.
  -XX:ParallelGCThreads=8
  -XX:ConcGCThreads=2

  # Enables the use of aggressive performance optimization features, which are
  # expected to become default in upcoming releases. By default, this option is
  # disabled and experimental performance features are not used.
  -XX:+AggressiveOpts

  # Enables touching of every page on the Java heap during JVM initialization.
  # This gets all pages into the memory before entering the main() method. The
  # option can be used in testing to simulate a long-running system with all
  # virtual memory mapped to physical memory. By default, this option is
  # disabled and all pages are committed as JVM heap space fills.
  -XX:+AlwaysPreTouch

  # Another way that applications can interact with garbage collection is by
  # invoking full garbage collections explicitly by calling System.gc(). This
  # can force a major collection to be done when it may not be necessary (for
  # example, when a minor collection would suffice), and so in general should
  # be avoided. The performance effect of explicit garbage collections can be
  # measured by disabling them using the flag -XX:+DisableExplicitGC, which
  # causes the VM to ignore calls to System.gc().
  -XX:+DisableExplicitGC

  # Enables parallel reference processing. By default, this option is disabled.
  -XX:+ParallelRefProcEnabled

  # Enables the perfdata feature. This option is enabled by default to allow
  # JVM monitoring and performance testing. Disabling it suppresses the
  # creation of the hsperfdata_userid directories. To disable the perfdata
  # feature, specify -XX:-UsePerfData.
  -XX:-UsePerfData

  # Disables the use of compressed pointers. By default, this option is
  # enabled, and compressed pointers are used when Java heap sizes are less
  # than 32 GB. When this option is enabled, object references are represented
  # as 32-bit offsets instead of 64-bit pointers, which typically increases
  # performance when running the application with Java heap sizes less than 32
  # GB. This option works only for 64-bit JVMs.
  -XX:+UseCompressedOops

  -XX:+PerfDisableSharedMem

  # Source: https://cassiofernando.netlify.app/blog/minecraft-java-arguments
)

forge_jar=$(find /opt/minecraft -maxdepth 1 -type f -name 'forge*.jar')

if [[ ! -f "${forge_jar}" ]]; then
  echo "ERROR: Cannot find forge*.jar"
  exit 2
fi

if [[ ! -f 'eula.txt' ]]; then
  echo "eula=true" > eula.txt
fi

# Symlink to external volume
mkdir -p /mnt/minecraft/world
ln -s /mnt/minecraft/world /opt/minecraft/world

FLASK_APP=/opt/minecraft/bin/healthcheck.py flask run -h 0.0.0.0 -p 8443 &

exec java "${JVM_ARGS[@]}" -jar "${forge_jar}" nogui 2>&1
